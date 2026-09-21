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

/// How FlowSend will reach this device for a transfer. Chosen automatically
/// by the Smart Connection layer — the user never sees these details.
enum ConnectionMethod {
  /// Both devices already reachable on the same Wi-Fi/LAN subnet.
  lan,

  /// No common Wi-Fi network — a direct Wi-Fi Direct (P2P) link is used.
  wifiDirect,

  /// Wi-Fi Direct is unavailable — a Local-Only Hotspot fallback is used.
  localHotspot,

  /// Method not yet determined.
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
    this.connectionMethod = ConnectionMethod.unknown,
    this.p2pDeviceAddress,
  });

  /// Wi-Fi Direct peer MAC address, present only for devices discovered via
  /// Wi-Fi Direct before a P2P group/IP address exists.
  final String? p2pDeviceAddress;

  /// Best connection path Smart Connection determined for this device.
  final ConnectionMethod connectionMethod;

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
    ConnectionMethod? connectionMethod,
    String? p2pDeviceAddress,
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
      connectionMethod: connectionMethod ?? this.connectionMethod,
      p2pDeviceAddress: p2pDeviceAddress ?? this.p2pDeviceAddress,
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
