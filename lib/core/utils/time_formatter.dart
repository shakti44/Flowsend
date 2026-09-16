/// Utility for formatting time durations into human-readable strings.
/// Used for transfer ETA and duration display.
abstract final class TimeFormatter {
  /// Format a duration for display in the transfer screen.
  /// Examples: 10s, 1m 14s, 2h 3m
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    if (minutes > 0) {
      return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
    }
    return '${seconds}s';
  }

  /// Format seconds remaining for ETA display.
  /// Examples: "10 seconds remaining", "1 minute remaining", "2 minutes 30 seconds remaining"
  static String formatEta(int seconds) {
    if (seconds <= 0) return 'Almost done...';
    return '${formatDuration(Duration(seconds: seconds))} remaining';
  }

  /// Format duration as HH:MM:SS or MM:SS for the telemetry counter.
  static String formatClock(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  /// Format a [DateTime] as relative text.
  /// Examples: "Just now", "12m ago", "Yesterday", "Sep 14"
  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    // Older than a week — show date
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
