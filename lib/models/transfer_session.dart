import 'selected_file.dart';
import 'discovered_device.dart';

/// The current state of a transfer session.
enum TransferState {
  queued,
  connecting,
  transferring,
  paused,
  interrupted,
  resuming,
  completed,
  failed,
  cancelled,
}

/// Represents one file-chunk transfer record for resume support.
class ChunkRecord {
  const ChunkRecord({
    required this.index,
    required this.offset,
    required this.length,
    required this.checksum,
    this.isVerified = false,
  });

  final int index;
  final int offset;
  final int length;

  /// SHA-256 checksum of this chunk.
  final String checksum;
  final bool isVerified;

  ChunkRecord copyWith({bool? isVerified}) => ChunkRecord(
        index: index,
        offset: offset,
        length: length,
        checksum: checksum,
        isVerified: isVerified ?? this.isVerified,
      );
}

/// Progress snapshot for a single file within a session.
class FileTransferProgress {
  const FileTransferProgress({
    required this.file,
    required this.transferredBytes,
    this.verifiedChunks = const [],
  });

  final SelectedFile file;
  final int transferredBytes;
  final List<ChunkRecord> verifiedChunks;

  double get fraction =>
      file.sizeBytes > 0 ? transferredBytes / file.sizeBytes : 0.0;

  int get percentInt => (fraction * 100).round().clamp(0, 100);
}

/// The full state of a transfer session.
class TransferSession {
  TransferSession({
    required this.id,
    required this.files,
    required this.targetDevice,
    required this.startedAt,
    this.state = TransferState.queued,
    this.currentFileIndex = 0,
    this.overallTransferredBytes = 0,
    this.speedBytesPerSecond = 0,
    this.etaSeconds = 0,
    this.fileProgress = const [],
    this.completedAt,
    this.fileIntegrityResults = const {},
    this.errorMessage,
    this.sessionCheckpoint,
  });

  final String id;
  final List<SelectedFile> files;
  final DiscoveredDevice targetDevice;
  final DateTime startedAt;

  TransferState state;
  int currentFileIndex;
  int overallTransferredBytes;
  int speedBytesPerSecond;
  int etaSeconds;
  List<FileTransferProgress> fileProgress;
  DateTime? completedAt;

  /// Map of file path → SHA-256 verified result.
  Map<String, bool> fileIntegrityResults;
  String? errorMessage;

  /// Byte offset to resume from after interruption.
  int? sessionCheckpoint;

  int get totalBytes =>
      files.fold(0, (sum, f) => sum + f.sizeBytes);

  double get overallFraction =>
      totalBytes > 0 ? overallTransferredBytes / totalBytes : 0.0;

  int get overallPercent => (overallFraction * 100).round().clamp(0, 100);

  SelectedFile? get currentFile =>
      currentFileIndex < files.length ? files[currentFileIndex] : null;

  int get remainingFileCount =>
      (files.length - currentFileIndex).clamp(0, files.length);

  Duration get elapsed => (completedAt ?? DateTime.now()).difference(startedAt);

  bool get isActive =>
      state == TransferState.connecting ||
      state == TransferState.transferring ||
      state == TransferState.resuming;

  bool get isTerminal =>
      state == TransferState.completed ||
      state == TransferState.failed ||
      state == TransferState.cancelled;
}
