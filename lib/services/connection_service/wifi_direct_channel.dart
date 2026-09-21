import 'dart:async';

import 'package:flutter/services.dart';

/// Raw platform-channel bridge to the native Android Wi-Fi Direct (P2P) APIs.
/// Only used when two devices are NOT on the same Wi-Fi network — the
/// existing same-Wi-Fi LAN path never touches this class.
///
/// No-op / throws [UnsupportedError] on platforms without a native
/// implementation (iOS, desktop, web); [SmartConnectionService] treats that
/// as "Wi-Fi Direct unavailable" and moves to the next fallback.
class WifiDirectChannel {
  WifiDirectChannel._();
  static final WifiDirectChannel instance = WifiDirectChannel._();

  static const _method = MethodChannel('flowsend/wifi_direct');
  static const _peersChannel = EventChannel('flowsend/wifi_direct/peers');
  static const _statusChannel = EventChannel('flowsend/wifi_direct/status');

  Stream<List<WifiDirectPeer>>? _peersStream;
  Stream<WifiDirectStatusEvent>? _statusStream;

  Future<bool> isSupported() async {
    try {
      return await _method.invokeMethod<bool>('isSupported') ?? false;
    } on Object {
      return false;
    }
  }

  Future<void> startDiscovery() => _method.invokeMethod<void>('startDiscovery');

  Future<void> stopDiscovery() => _method.invokeMethod<void>('stopDiscovery');

  Future<void> connect(String deviceAddress) =>
      _method.invokeMethod<void>('connect', {'address': deviceAddress});

  Future<void> cancelConnect() => _method.invokeMethod<void>('cancelConnect');

  /// Tears down the temporary P2P group. Safe to call even if no group
  /// exists — never touches the device's normal Wi-Fi connection.
  Future<void> disconnect() => _method.invokeMethod<void>('disconnect');

  Stream<List<WifiDirectPeer>> get peersStream {
    return _peersStream ??= _peersChannel.receiveBroadcastStream().map((event) {
      final list = (event as List).cast<Map<dynamic, dynamic>>();
      return list
          .map((item) => WifiDirectPeer(
                name: item['name'] as String? ?? 'Nearby device',
                address: item['address'] as String,
                status: item['status'] as int? ?? -1,
              ))
          .toList();
    }).asBroadcastStream();
  }

  Stream<WifiDirectStatusEvent> get statusStream {
    return _statusStream ??= _statusChannel.receiveBroadcastStream().map((event) {
      final map = (event as Map).cast<String, dynamic>();
      return WifiDirectStatusEvent(
        event: map['event'] as String,
        connected: map['connected'] as bool? ?? false,
        isGroupOwner: map['isGroupOwner'] as bool? ?? false,
        groupOwnerAddress: map['groupOwnerAddress'] as String?,
        radioEnabled: map['enabled'] as bool?,
      );
    }).asBroadcastStream();
  }
}

class WifiDirectPeer {
  const WifiDirectPeer({required this.name, required this.address, required this.status});
  final String name;
  final String address;

  /// Mirrors [WifiP2pDevice] status constants (0=connected, 3=available...).
  final int status;
}

class WifiDirectStatusEvent {
  const WifiDirectStatusEvent({
    required this.event,
    required this.connected,
    required this.isGroupOwner,
    this.groupOwnerAddress,
    this.radioEnabled,
  });

  final String event;
  final bool connected;
  final bool isGroupOwner;
  final String? groupOwnerAddress;
  final bool? radioEnabled;
}
