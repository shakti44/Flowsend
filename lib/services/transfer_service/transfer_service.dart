import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/discovered_device.dart';
import '../../models/selected_file.dart';
import '../../models/transfer_session.dart';
import '../network_service/transfer_transport.dart';
import '../network_service/mock_transfer_transport.dart';
import '../network_service/tcp_transfer_transport.dart';

/// Manages the complete lifecycle of a file transfer session.
/// Drives the state machine and exposes a stream of [TransferSession] updates.
class TransferService extends ChangeNotifier {
  TransferService({TransferTransport? transport, bool useMockTransport = false})
      : _transport = transport ??
            (useMockTransport ? MockTransferTransport() : TcpTransferTransport());

  final TransferTransport _transport;
  static const _uuid = Uuid();

  TransferSession? _activeSession;
  StreamSubscription<TransportProgress>? _progressSubscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  /// The current active session, if any.
  TransferSession? get activeSession => _activeSession;

  /// Convenience: current transfer state.
  TransferState get state =>
      _activeSession?.state ?? TransferState.queued;

  /// Start a new transfer session.
  Future<void> startTransfer({
    required List<SelectedFile> files,
    required DiscoveredDevice targetDevice,
  }) async {
    assert(files.isNotEmpty, 'Cannot start transfer with empty file list');

    _activeSession = TransferSession(
      id: _uuid.v4(),
      files: files,
      targetDevice: targetDevice,
      startedAt: DateTime.now(),
      state: TransferState.connecting,
      fileProgress: files
          .map((f) => FileTransferProgress(file: f, transferredBytes: 0))
          .toList(),
    );
    notifyListeners();

    final available = await _transport.isAvailable;
    if (!available) {
      _activeSession!.state = TransferState.failed;
      _activeSession!.errorMessage = 'No compatible transfer transport is available.';
      notifyListeners();
      return;
    }

    _activeSession!.state = TransferState.transferring;
    notifyListeners();

    _startTransportStream();
  }

  void _startTransportStream({int? resumeFromByte}) {
    if (_activeSession == null) return;

    final session = _activeSession!;

    _progressSubscription = _transport.send(
      files: session.files,
      peerAddress: session.targetDevice.address ?? '192.168.1.100',
      peerPort: session.targetDevice.port ?? 8765,
      sessionId: session.id,
      resumeFromByte: resumeFromByte,
    ).listen(
      (progress) => _onProgress(progress),
      onDone: () => _onTransportDone(),
      onError: (Object e) => _onTransportError(e),
    );
  }

  void _onProgress(TransportProgress progress) {
    final session = _activeSession;
    if (session == null || session.isTerminal) return;

    session.overallTransferredBytes = progress.totalBytesTransferred;
    session.speedBytesPerSecond = progress.speedBytesPerSecond;

    final remaining = session.totalBytes - progress.totalBytesTransferred;
    session.etaSeconds = progress.speedBytesPerSecond > 0
        ? (remaining / progress.speedBytesPerSecond).ceil()
        : 0;

    session.currentFileIndex =
        progress.fileIndex.clamp(0, session.files.length - 1);

    // Update per-file progress
    if (progress.fileIndex < session.fileProgress.length) {
      session.fileProgress[progress.fileIndex] = FileTransferProgress(
        file: session.files[progress.fileIndex],
        transferredBytes: progress.fileBytesTransferred,
      );
    }

    if (progress.isComplete && session.state == TransferState.transferring) {
      session.state = TransferState.completed;
      session.completedAt = DateTime.now();
      _verifyIntegrity(session);
    }

    notifyListeners();
  }

  Future<void> _verifyIntegrity(TransferSession session) async {
    // In production: compare sender-computed hashes with receiver-computed hashes.
    // Mock: mark all files as verified after a short delay.
    await Future.delayed(const Duration(milliseconds: 500));
    for (final file in session.files) {
      session.fileIntegrityResults[file.path] = true;
    }
    notifyListeners();
  }

  void _onTransportDone() {
    final session = _activeSession;
    if (session == null) return;
    if (session.state == TransferState.transferring) {
      session.state = TransferState.completed;
      session.completedAt = DateTime.now();
      notifyListeners();
    }
  }

  void _onTransportError(Object error) {
    final session = _activeSession;
    if (session == null || session.isTerminal) return;

    debugPrint('[TransferService] Transport error: $error');
    _handleInterruption();
  }

  void _handleInterruption() {
    final session = _activeSession;
    if (session == null) return;

    session.state = TransferState.interrupted;
    session.sessionCheckpoint = session.overallTransferredBytes;
    notifyListeners();

    // Auto-reconnect with backoff
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      _reconnectTimer = Timer(_reconnectDelay, () => _attemptResume());
    } else {
      session.state = TransferState.failed;
      session.errorMessage =
          'Could not reconnect after $_maxReconnectAttempts attempts.';
      notifyListeners();
    }
  }

  Future<void> _attemptResume() async {
    final session = _activeSession;
    if (session == null || session.state != TransferState.interrupted) return;

    session.state = TransferState.resuming;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    session.state = TransferState.transferring;
    notifyListeners();

    _startTransportStream(resumeFromByte: session.sessionCheckpoint);
  }

  /// Pause the active transfer.
  Future<void> pause() async {
    final session = _activeSession;
    if (session == null || !session.isActive) return;

    final checkpoint = await _transport.pause();
    session.state = TransferState.paused;
    session.sessionCheckpoint = checkpoint;
    notifyListeners();
  }

  /// Resume a paused transfer.
  Future<void> resume() async {
    final session = _activeSession;
    if (session == null || session.state != TransferState.paused) return;

    session.state = TransferState.transferring;
    notifyListeners();

    _startTransportStream(resumeFromByte: session.sessionCheckpoint);
  }

  /// Cancel the active transfer.
  Future<void> cancel() async {
    await _transport.cancel();
    _progressSubscription?.cancel();
    _reconnectTimer?.cancel();

    final session = _activeSession;
    if (session != null) {
      session.state = TransferState.cancelled;
      notifyListeners();
    }
  }

  /// Simulate a connection interruption for testing.
  void simulateInterruption() {
    _progressSubscription?.cancel();
    _handleInterruption();
  }

  /// Compute SHA-256 of a file using the crypto package.
  /// Reads the file in 64 KB chunks — safe for any file size.
  static Future<String> computeHash(String filePath) async {
    final file = File(filePath);
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);
    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();
    return output.events.single.toString();
  }

  void clear() {
    _progressSubscription?.cancel();
    _reconnectTimer?.cancel();
    _activeSession = null;
    _reconnectAttempts = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _reconnectTimer?.cancel();
    _transport.dispose();
    super.dispose();
  }
}

// Accumulator sink for sha256 chunked hashing
class AccumulatorSink<T> implements Sink<T> {
  final List<T> events = <T>[];

  @override
  void add(T data) => events.add(data);

  @override
  void close() {}
}
