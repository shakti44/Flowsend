import 'selected_file.dart';

class RemoteFileInfo {
  const RemoteFileInfo({
    required this.relativePath,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String relativePath;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
}

enum DuplicateStatus { newFile, exactDuplicate, possibleDuplicate, largeFile }

class DuplicateFileAnalysis {
  DuplicateFileAnalysis({
    required this.file,
    required this.status,
    this.remoteMatches = const [],
    this.isIncluded = true,
  });

  final SelectedFile file;
  DuplicateStatus status;
  final List<RemoteFileInfo> remoteMatches;
  bool isIncluded;

  bool get isExact => status == DuplicateStatus.exactDuplicate;
  bool get isPossible => status == DuplicateStatus.possibleDuplicate;
}

class DeviceDuplicateAnalysis {
  DeviceDuplicateAnalysis({required this.deviceName, required this.files});

  final String deviceName;
  final List<DuplicateFileAnalysis> files;

  int get exactCount => files.where((item) => item.isExact).length;
  int get possibleCount => files.where((item) => item.isPossible).length;
  int get newCount => files.where((item) => item.status == DuplicateStatus.newFile).length;
  int get largeCount => files.where((item) => item.status == DuplicateStatus.largeFile).length;
  int get duplicateBytes => files
      .where((item) => item.isExact)
      .fold(0, (sum, item) => sum + item.file.sizeBytes);
  int get includedBytes => files
      .where((item) => item.isIncluded)
      .fold(0, (sum, item) => sum + item.file.sizeBytes);
  List<SelectedFile> get includedFiles => files
      .where((item) => item.isIncluded)
      .map((item) => item.file)
      .toList(growable: false);
}
