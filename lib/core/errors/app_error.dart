/// Typed errors for the FlowSend application.
/// All user-facing messages are in plain English that explains:
/// 1. What happened  2. Whether files are safe  3. What to do next.
enum ErrorType {
  permissionDenied,
  fileNotFound,
  fileAccessDenied,
  storageUnavailable,
  noDevicesFound,
  connectionFailed,
  connectionInterrupted,
  transferFailed,
  transferCancelled,
  integrityVerificationFailed,
  qrExpired,
  sessionExpired,
  unknownError,
}

/// Structured error with user-friendly messaging.
class AppError implements Exception {
  const AppError({
    required this.type,
    required this.message,
    required this.description,
    required this.filesAreSafe,
    required this.suggestedAction,
    this.technicalDetail,
  });

  final ErrorType type;

  /// Short headline shown to the user.
  final String message;

  /// Longer explanation paragraph.
  final String description;

  /// Whether the user's files are safe after this error.
  final bool filesAreSafe;

  /// Call-to-action text for the primary button.
  final String suggestedAction;

  /// Technical detail for logs (never shown in UI).
  final String? technicalDetail;

  /// Factory constructors for common error cases.
  factory AppError.permissionDenied(String permission) => AppError(
        type: ErrorType.permissionDenied,
        message: 'Permission required',
        description: 'FlowSend needs $permission permission to work. '
            'Please enable it in Settings.',
        filesAreSafe: true,
        suggestedAction: 'Open Settings',
        technicalDetail: 'Permission denied: $permission',
      );

  factory AppError.noDevicesFound() => const AppError(
        type: ErrorType.noDevicesFound,
        message: 'No devices found',
        description: 'Make sure both devices are on the same Wi-Fi network '
            'and have FlowSend open.',
        filesAreSafe: true,
        suggestedAction: 'Try again',
      );

  factory AppError.connectionFailed(String deviceName) => AppError(
        type: ErrorType.connectionFailed,
        message: 'Connection failed',
        description: 'Could not connect to $deviceName. '
            'Your files have not been sent.',
        filesAreSafe: true,
        suggestedAction: 'Try again',
      );

  factory AppError.connectionInterrupted(int progressPercent) => AppError(
        type: ErrorType.connectionInterrupted,
        message: 'Connection interrupted',
        description: "Don't worry — your transfer is safe. "
            'FlowSend paused at $progressPercent% and will resume '
            'automatically when the connection is restored.',
        filesAreSafe: true,
        suggestedAction: 'Reconnecting...',
      );

  factory AppError.transferFailed() => const AppError(
        type: ErrorType.transferFailed,
        message: 'Transfer failed',
        description: 'The transfer could not be completed. '
            'Your original files are safe on your device.',
        filesAreSafe: true,
        suggestedAction: 'Try again',
      );

  factory AppError.integrityFailed(String fileName) => AppError(
        type: ErrorType.integrityVerificationFailed,
        message: 'File verification failed',
        description: 'The integrity check for $fileName did not pass. '
            'The file may be corrupted. Your original file is still safe.',
        filesAreSafe: true,
        suggestedAction: 'Retry transfer',
        technicalDetail: 'SHA-256 mismatch for $fileName',
      );

  factory AppError.sessionExpired() => const AppError(
        type: ErrorType.sessionExpired,
        message: 'Session expired',
        description: 'The transfer session has expired. '
            'Your files are safe — just start a new transfer.',
        filesAreSafe: true,
        suggestedAction: 'Start new transfer',
      );

  @override
  String toString() => 'AppError(${type.name}): $message';
}
