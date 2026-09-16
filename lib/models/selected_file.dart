import 'dart:io';

/// Represents a file selected by the user for transfer.
class SelectedFile {
  const SelectedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.mimeType,
    required this.lastModified,
  });

  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final String mimeType;
  final DateTime lastModified;

  /// Returns a [File] object for this selected file.
  File get file => File(path);

  /// File extension, lowercased (e.g. 'mp4', 'pdf').
  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// High-level category for display purposes.
  FileCategory get category {
    switch (extension) {
      case 'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' || 'heic' || 'raw':
        return FileCategory.photo;
      case 'mp4' || 'mov' || 'avi' || 'mkv' || 'webm' || 'm4v':
        return FileCategory.video;
      case 'pdf' || 'doc' || 'docx' || 'xls' || 'xlsx' || 'ppt' || 'pptx' ||
            'key' || 'pages' || 'numbers':
        return FileCategory.document;
      default:
        return FileCategory.file;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SelectedFile && path == other.path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'SelectedFile($name, ${sizeBytes}B)';
}

/// High-level file category for display icons and filters.
enum FileCategory {
  photo,
  video,
  document,
  file,
}
