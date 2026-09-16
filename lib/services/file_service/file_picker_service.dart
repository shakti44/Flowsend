import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
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
      withReadStream: false,
    );
    return _convertResult(result);
  }

  @override
  Future<List<SelectedFile>> pickPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: false,
    );
    return _convertResult(result);
  }

  @override
  Future<List<SelectedFile>> pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
      withData: false,
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
    );
    return _convertResult(result);
  }

  @override
  Future<List<SelectedFile>> pickDirectory() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
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

  List<SelectedFile> _convertResult(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) return [];

    return result.files.map((pf) {
      final path = pf.path ?? '';
      final file = File(path);
      final stat = file.existsSync() ? file.statSync() : null;

      return SelectedFile(
        id: _uuid.v4(),
        name: pf.name,
        path: path,
        sizeBytes: pf.size,
        mimeType: _inferMimeType(p.extension(pf.name)),
        lastModified: stat?.modified ?? DateTime.now(),
      );
    }).toList();
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
