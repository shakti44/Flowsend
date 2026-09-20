import '../../models/selected_file.dart';

/// Abstract interface for file selection.
/// Abstracts over file_picker to allow future web/desktop implementations.
abstract class FileService {
  /// Pick multiple files of any type from the device.
  Future<List<SelectedFile>> pickFiles();

  /// Pick files filtered to photos only.
  Future<List<SelectedFile>> pickPhotos();

  /// Pick files filtered to videos only.
  Future<List<SelectedFile>> pickVideos();

  /// Pick files filtered to documents (PDF, Office, etc.).
  Future<List<SelectedFile>> pickDocuments();

  /// Pick Android APK packages where the platform exposes them.
  Future<List<SelectedFile>> pickApps();

  /// Pick a directory and return all files within it (recursive).
  Future<List<SelectedFile>> pickDirectory();

  /// Calculate SHA-256 hash of a file for integrity verification.
  /// Reads the file in chunks — safe for large files.
  Future<String> computeFileHash(String filePath);
}
