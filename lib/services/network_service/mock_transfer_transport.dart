import 'dart:async';
import 'dart:math';
import '../../models/selected_file.dart';
import 'transfer_transport.dart';

/// ⚠️ DEVELOPMENT/TESTING ONLY — MockTransferTransport
///
/// Simulates a file transfer at ~80 MB/s with realistic progress events.
/// Progress is driven by a timer — NOT real file I/O.
///
/// To implement real transport, create a class implementing [TransferTransport]
/// using TCP sockets, Wi-Fi Direct, WebRTC, or another protocol.
class MockTransferTransport implements TransferTransport {
  static const int _simulatedSpeedBytesPerSec = 80 * 1024 * 1024; // 80 MB/s
  static const Duration _tickInterval = Duration(milliseconds: 100);

  bool _isCancelled = false;
  bool _isPaused = false;
  int _pausedAtByte = 0;
  StreamController<TransportProgress>? _controller;
  Timer? _timer;
  final _random = Random();

  @override
  String get name => 'MockTransport (Development Only)';

  @override
  Future<bool> get isAvailable async => true;

  @override
  Stream<TransportProgress> send({
    required List<SelectedFile> files,
    required String peerAddress,
    required int peerPort,
    required String sessionId,
    int? resumeFromByte,
  }) {
    _isCancelled = false;
    _isPaused = false;
    _controller = StreamController<TransportProgress>.broadcast();

    final totalBytes = files.fold<int>(0, (sum, f) => sum + f.sizeBytes);
    final tickBytes =
        (_simulatedSpeedBytesPerSec * _tickInterval.inMilliseconds / 1000)
            .round();

    int overallTransferred = resumeFromByte ?? 0;
    int fileIndex = 0;
    int fileTransferred = 0;
    int chunkIndex = overallTransferred ~/ (64 * 1024);

    // Simulate realistic speed variance (±10%)
    int speedVariance() =>
        (_simulatedSpeedBytesPerSec * (0.9 + _random.nextDouble() * 0.2))
            .round();

    _timer = Timer.periodic(_tickInterval, (timer) {
      if (_isCancelled || _isPaused) {
        timer.cancel();
        if (_isCancelled) {
          _controller?.close();
        }
        return;
      }

      final thisTickBytes = min(tickBytes, totalBytes - overallTransferred);
      if (thisTickBytes <= 0) return;

      overallTransferred += thisTickBytes;
      fileTransferred += thisTickBytes;

      // Advance to next file if current file is done
      if (fileIndex < files.length &&
          fileTransferred >= files[fileIndex].sizeBytes) {
        fileTransferred = 0;
        fileIndex++;
      }

      final currentSpeed = speedVariance();
      chunkIndex++;

      _controller?.add(TransportProgress(
        fileIndex: fileIndex.clamp(0, files.length - 1),
        fileBytesTransferred: fileTransferred,
        totalBytesTransferred: overallTransferred,
        speedBytesPerSecond: currentSpeed,
        chunkIndex: chunkIndex,
        chunkChecksum: 'mock_sha256_chunk_$chunkIndex',
        isComplete: overallTransferred >= totalBytes,
      ));

      if (overallTransferred >= totalBytes) {
        timer.cancel();
        _controller?.close();
      }
    });

    return _controller!.stream;
  }

  @override
  Future<void> cancel() async {
    _isCancelled = true;
    _timer?.cancel();
    _controller?.close();
  }

  @override
  Future<int> pause() async {
    _isPaused = true;
    _timer?.cancel();
    return _pausedAtByte;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.close();
  }
}
