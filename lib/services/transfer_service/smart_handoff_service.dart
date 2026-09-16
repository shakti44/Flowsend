import 'package:path/path.dart' as p;

import '../../models/selected_file.dart';

class SmartHandoffRecommendation {
  const SmartHandoffRecommendation({
    required this.bestFiles,
    required this.screenshotCount,
    required this.lowDetailCount,
    required this.burstReducedCount,
    required this.largeVideoCount,
  });

  final List<SelectedFile> bestFiles;
  final int screenshotCount;
  final int lowDetailCount;
  final int burstReducedCount;
  final int largeVideoCount;

  int get filteredCount => screenshotCount + lowDetailCount + burstReducedCount;
}

/// Conservative, metadata-only handoff recommendations.
///
/// This deliberately does not claim to detect visual similarity or blur without
/// image-decoding metadata. It uses real filenames, MIME types, and byte sizes.
class SmartHandoffService {
  static const largeVideoThresholdBytes = 1 << 30;
  static const lowDetailThresholdBytes = 80 * 1024;

  SmartHandoffRecommendation recommend(List<SelectedFile> files) {
    final photos = files.where(_isPhoto).toList();
    final nonPhotos = files.where((file) => !_isPhoto(file)).toList();
    final selectedPhotos = <SelectedFile>[];
    var screenshotCount = 0;
    var lowDetailCount = 0;

    for (final file in photos) {
      if (_isScreenshot(file)) {
        screenshotCount++;
        continue;
      }
      if (file.sizeBytes < lowDetailThresholdBytes) {
        lowDetailCount++;
        continue;
      }
      selectedPhotos.add(file);
    }

    final burstGroups = <String, List<SelectedFile>>{};
    for (final file in selectedPhotos) {
      burstGroups.putIfAbsent(_burstKey(file), () => []).add(file);
    }

    final bestPhotos = <SelectedFile>[];
    var burstReducedCount = 0;
    for (final group in burstGroups.values) {
      if (group.length == 1) {
        bestPhotos.add(group.first);
        continue;
      }
      final best = [...group]..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      bestPhotos.add(best.first);
      burstReducedCount += group.length - 1;
    }

    return SmartHandoffRecommendation(
      bestFiles: [...nonPhotos, ...bestPhotos],
      screenshotCount: screenshotCount,
      lowDetailCount: lowDetailCount,
      burstReducedCount: burstReducedCount,
      largeVideoCount: files.where(_isLargeVideo).length,
    );
  }

  bool _isPhoto(SelectedFile file) => file.mimeType.startsWith('image/') ||
      const {'jpg', 'jpeg', 'png', 'heic', 'webp', 'gif'}.contains(file.extension);

  bool _isLargeVideo(SelectedFile file) =>
      file.mimeType.startsWith('video/') && file.sizeBytes >= largeVideoThresholdBytes;

  bool _isScreenshot(SelectedFile file) {
    final name = file.name.toLowerCase();
    return name.contains('screenshot') || name.contains('screen_shot') || name.contains('screencap');
  }

  String _burstKey(SelectedFile file) {
    final stem = p.basenameWithoutExtension(file.name).toLowerCase();
    return stem
        .replaceFirst(RegExp(r'(\s*\(\d+\)|[_-]\d+)$'), '')
        .replaceFirst(RegExp(r'[_-](burst|photo|image)$'), '');
  }
}
