import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/selected_file.dart';
import 'file_service.dart';

/// Real implementation of [FileService] using the file_picker package.
/// Reads files from the actual device storage.
class FilePickerService implements FileService {
  const FilePickerService();

  static const _uuid = Uuid();

  @override
  Future<List<SelectedFile>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
      withReadStream: true,
    );
    return _convertResult(result);
  }

  @override
  Future<List<SelectedFile>> pickPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: false,
      withReadStream: true,
    );
    return _convertResult(result);
  }

  @override
  Future<List<SelectedFile>> pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
      withData: false,
      withReadStream: true,
    );
    return _convertResult(result);
  }

  @override
  Future<List<SelectedFile>> pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'xls', 'xlsx',
        'ppt', 'pptx', 'key', 'pages', 'numbers', 'txt',
      ],
      allowMultiple: true,
      withData: false,
      withReadStream: true,
    );
    return _convertResult(result);
  }

  @override
  Future<List<SelectedFile>> pickDirectory() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
      withReadStream: true,
    );
    return _convertResult(result);
  }

  @override
  Future<String> computeFileHash(String filePath) async {
    // Read file in 64 KB chunks — safe for large files.
    final file = File(filePath);
    final output = _AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);
    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();
    return output.events.single.toString();
  }

  Future<List<SelectedFile>> _convertResult(FilePickerResult? result) async {
    if (result == null || result.files.isEmpty) return [];

    final files = <SelectedFile>[];
    for (final platformFile in result.files) {
      final path = await _materializeLocalPath(platformFile);
      final file = File(path);
      final stat = await file.stat();
      files.add(
        SelectedFile(
          id: _uuid.v4(),
          name: platformFile.name,
          path: path,
          sizeBytes: stat.size,
          mimeType: _inferMimeType(p.extension(platformFile.name)),
          lastModified: stat.modified,
        ),
      );
    }
    return files;
  }

  /// Android's document picker may return a content:// URI with no normal
  /// filesystem path. Materialize that provider stream once so the existing
  /// streaming transfer engine can safely reopen it later.
  Future<String> _materializeLocalPath(PlatformFile platformFile) async {
    final path = platformFile.path;
    if (path != null && path.isNotEmpty && !path.startsWith('content://')) {
      final file = File(path);
      if (await file.exists()) return path;
    }

    final readStream = platformFile.readStream;
    if (readStream == null) {
      throw StateError('Unable to read selected file: ${platformFile.name}');
    }
    final cacheDirectory = await getTemporaryDirectory();
    final selectedDirectory = Directory(
      p.join(cacheDirectory.path, 'flowsend_selected_files'),
    );
    await selectedDirectory.create(recursive: true);
    final localPath = p.join(
      selectedDirectory.path,
      '${_uuid.v4()}_${platformFile.name}',
    );
    final output = File(localPath).openWrite();
    await for (final chunk in readStream) {
      output.add(chunk);
    }
    await output.close();
    return localPath;
  }

  static String _inferMimeType(String ext) {
    final e = ext.replaceFirst('.', '').toLowerCase();
    const map = {
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
      'gif': 'image/gif', 'webp': 'image/webp', 'heic': 'image/heic',
      'mp4': 'video/mp4', 'mov': 'video/quicktime', 'avi': 'video/x-msvideo',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'zip': 'application/zip',
    };
    return map[e] ?? 'application/octet-stream';
  }
}

// Accumulator sink for sha256 chunked hashing
class _AccumulatorSink<T> implements Sink<T> {
  final List<T> events = <T>[];

  @override
  void add(T data) => events.add(data);

  @override
  void close() {}
}
