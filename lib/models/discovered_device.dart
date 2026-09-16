/// Represents a device discovered on the local network.
enum DeviceStatus {
  connected,
  nearby,
  available,
  offline,
}

enum DevicePlatform {
  android,
  ios,
  macos,
  windows,
  linux,
  unknown,
}

class DiscoveredDevice {
  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.status,
    this.address,
    this.port,
    this.signalStrength,
    this.protocolInfo,
    this.lastSeen,
    this.isTrusted = false,
  });

  /// Unique device identifier (hardware ID or session ID).
  final String id;

  /// Human-readable device name.
  final String name;

  final DevicePlatform platform;
  final DeviceStatus status;

  /// Network address for connection.
  final String? address;
  final int? port;

  /// Signal quality, 0.0–1.0.
  final double? signalStrength;

  /// Protocol detail string, e.g. "macOS Sonoma · Strong (5GHz Direct)".
  final String? protocolInfo;

  final DateTime? lastSeen;

  /// Whether this device is in the user's trusted device list.
  final bool isTrusted;

  bool get isOnline =>
      status == DeviceStatus.connected || status == DeviceStatus.nearby;

  String get statusLabel {
    return switch (status) {
      DeviceStatus.connected => 'Connected',
      DeviceStatus.nearby => 'Nearby',
      DeviceStatus.available => 'Available',
      DeviceStatus.offline => 'Offline',
    };
  }

  DiscoveredDevice copyWith({
    String? id,
    String? name,
    DevicePlatform? platform,
    DeviceStatus? status,
    String? address,
    int? port,
    double? signalStrength,
    String? protocolInfo,
    DateTime? lastSeen,
    bool? isTrusted,
  }) {
    return DiscoveredDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      address: address ?? this.address,
      port: port ?? this.port,
      signalStrength: signalStrength ?? this.signalStrength,
      protocolInfo: protocolInfo ?? this.protocolInfo,
      lastSeen: lastSeen ?? this.lastSeen,
      isTrusted: isTrusted ?? this.isTrusted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DiscoveredDevice && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DiscoveredDevice($name, ${status.name})';
}
