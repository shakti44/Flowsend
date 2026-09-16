/// Utility for formatting file sizes in a human-readable form.
/// Used throughout the app for displaying file and transfer sizes.
abstract final class FileSizeFormatter {
  static const int _kb = 1024;
  static const int _mb = _kb * 1024;
  static const int _gb = _mb * 1024;
  static const int _tb = _gb * 1024;

  /// Format bytes into a human-readable string with appropriate unit.
  /// Examples: 420000000 → "420 MB", 1800000000 → "1.8 GB"
  static String format(int bytes, {int decimals = 1}) {
    if (bytes < 0) return '0 B';
    if (bytes < _kb) return '$bytes B';
    if (bytes < _mb) {
      final value = bytes / _kb;
      return '${_stripTrailingZero(value.toStringAsFixed(decimals))} KB';
    }
    if (bytes < _gb) {
      final value = bytes / _mb;
      return '${_stripTrailingZero(value.toStringAsFixed(decimals))} MB';
    }
    if (bytes < _tb) {
      final value = bytes / _gb;
      return '${_stripTrailingZero(value.toStringAsFixed(decimals))} GB';
    }
    final value = bytes / _tb;
    return '${_stripTrailingZero(value.toStringAsFixed(decimals))} TB';
  }

  /// Format bytes/second into a speed string.
  /// Examples: 82000000 → "82 MB/s"
  static String formatSpeed(int bytesPerSecond) {
    return '${format(bytesPerSecond, decimals: 1)}/s';
  }

  static String _stripTrailingZero(String s) {
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}
