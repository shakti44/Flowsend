import 'discovered_device.dart';

/// A record of a completed (or failed) transfer, persisted to history.
class TransferRecord {
  const TransferRecord({
    required this.id,
    required this.sessionId,
    required this.fileName,
    required this.fileCount,
    required this.totalSizeBytes,
    required this.direction,
    required this.peerDevice,
    required this.startedAt,
    required this.completedAt,
    required this.state,
    this.averageSpeedBytesPerSecond,
    this.integrityVerified = false,
    this.errorMessage,
  });

  final String id;
  final String sessionId;

  /// Display name (single file name, or "3 files" for batch).
  final String fileName;
  final int fileCount;
  final int totalSizeBytes;
  final TransferDirection direction;
  final DiscoveredDevice peerDevice;
  final DateTime startedAt;
  final DateTime completedAt;
  final TransferRecordState state;
  final int? averageSpeedBytesPerSecond;
  final bool integrityVerified;
  final String? errorMessage;

  Duration get duration => completedAt.difference(startedAt);

  bool get isSuccess => state == TransferRecordState.completed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'fileName': fileName,
        'fileCount': fileCount,
        'totalSizeBytes': totalSizeBytes,
        'direction': direction.name,
        'peerDeviceName': peerDevice.name,
        'peerDevicePlatform': peerDevice.platform.name,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'state': state.name,
        'averageSpeedBytesPerSecond': averageSpeedBytesPerSecond,
        'integrityVerified': integrityVerified,
        'errorMessage': errorMessage,
      };

  factory TransferRecord.fromJson(Map<String, dynamic> json) => TransferRecord(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        fileName: json['fileName'] as String,
        fileCount: json['fileCount'] as int,
        totalSizeBytes: json['totalSizeBytes'] as int,
        direction: TransferDirection.values.byName(json['direction'] as String),
        peerDevice: DiscoveredDevice(
          id: json['sessionId'] as String,
          name: json['peerDeviceName'] as String,
          platform: DevicePlatform.values.byName(
              json['peerDevicePlatform'] as String? ?? 'unknown'),
          status: DeviceStatus.offline,
        ),
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: DateTime.parse(json['completedAt'] as String),
        state: TransferRecordState.values.byName(json['state'] as String),
        averageSpeedBytesPerSecond:
            json['averageSpeedBytesPerSecond'] as int?,
        integrityVerified: json['integrityVerified'] as bool? ?? false,
        errorMessage: json['errorMessage'] as String?,
      );
}

enum TransferDirection { sent, received }

enum TransferRecordState { completed, failed, cancelled, interrupted }
