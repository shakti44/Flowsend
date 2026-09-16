import '../../models/selected_file.dart';

/// Abstract transport layer for file transfer.
/// The UI is decoupled from any specific networking technology.
///
/// Future implementations:
/// - Wi-Fi Direct / P2P (Android: WifiP2pManager, iOS: Multipeer Connectivity)
/// - Local TCP socket over shared Wi-Fi
/// - WebRTC P2P data channel
/// - Internet relay (TURN server)
/// - Bluetooth LE (small files)
abstract class TransferTransport {
  /// Name of this transport for display and diagnostics.
  String get name;

  /// Whether this transport is available on the current platform.
  Future<bool> get isAvailable;

  /// Send [files] to the peer identified by [address]:[port].
  /// Returns a stream of [TransportProgress] events.
  ///
  /// The transport MUST:
  /// - Stream data in chunks (never load an entire file into memory)
  /// - Support cancellation via [cancel()]
  /// - Report progress frequently (at least every 100ms)
  /// - Provide per-chunk checksums for resume support
  Stream<TransportProgress> send({
    required List<SelectedFile> files,
    required String peerAddress,
    required int peerPort,
    required String sessionId,
    int? resumeFromByte,
  });

  /// Cancel the active transfer.
  Future<void> cancel();

  /// Pause the active transfer. The current byte offset is returned
  /// so the session can resume from the correct position.
  Future<int> pause();

  /// Clean up all resources.
  void dispose();
}

/// Progress event emitted by a [TransferTransport] during a send operation.
class TransportProgress {
  const TransportProgress({
    required this.fileIndex,
    required this.fileBytesTransferred,
    required this.totalBytesTransferred,
    required this.speedBytesPerSecond,
    this.chunkIndex,
    this.chunkChecksum,
    this.isComplete = false,
    this.error,
  });

  final int fileIndex;
  final int fileBytesTransferred;
  final int totalBytesTransferred;
  final int speedBytesPerSecond;

  /// Chunk index for resume bookkeeping.
  final int? chunkIndex;

  /// SHA-256 of the last transferred chunk.
  final String? chunkChecksum;

  final bool isComplete;
  final String? error;

  bool get hasError => error != null;
}
