import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'device_service.dart';
import '../../models/discovered_device.dart';

/// Discovers FlowSend peers on the local network using UDP announcements.
class LanDeviceService implements DeviceService {
  LanDeviceService({this.discoveryPort = 8766, this.transferPort = 8765});

  final int discoveryPort;
  final int transferPort;
  final _controller = StreamController<List<DiscoveredDevice>>.broadcast();
  final _eventController = StreamController<NearbyEventAnnouncement>.broadcast();
  final Map<String, DiscoveredDevice> _knownDevices = {};
  RawDatagramSocket? _socket;
  Timer? _announcementTimer;
  bool _isDiscovering = false;
  bool _isAdvertising = false;
  late final String _deviceId = '${Platform.localHostname}-${DateTime.now().microsecondsSinceEpoch}';
  String? _deviceName;
  String? _activeEventId;
  String? _activeEventName;

  @override
  Stream<List<DiscoveredDevice>> get devicesStream => _controller.stream;
  Stream<NearbyEventAnnouncement> get eventStream => _eventController.stream;

  @override
  List<DiscoveredDevice> get devices => List.unmodifiable(_knownDevices.values);

  @override
  bool get isDiscovering => _isDiscovering;

  @override
  Future<void> startDiscovery() async {
    _isDiscovering = true;
    await _ensureSocket();
    _socket?.broadcastEnabled = true;
    unawaited(_sendAnnouncement());
  }

  @override
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    _stopIfUnused();
  }

  @override
  Future<void> startAdvertising() async {
    _isAdvertising = true;
    await _ensureSocket();
    _socket?.broadcastEnabled = true;
    unawaited(_sendAnnouncement());
  }

  @override
  Future<void> stopAdvertising() async {
    _isAdvertising = false;
    _stopIfUnused();
  }

  Future<void> advertiseEvent({required String eventId, required String eventName}) async {
    _activeEventId = eventId;
    _activeEventName = eventName;
    _isAdvertising = true;
    await _ensureSocket();
    _socket?.broadcastEnabled = true;
    unawaited(_sendAnnouncement());
  }

  Future<void> stopEventAdvertising() async {
    _activeEventId = null;
    _activeEventName = null;
    _stopIfUnused();
  }

  Future<void> _ensureSocket() async {
    if (_socket != null) return;
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
      reusePort: true,
    );
    _socket!.readEventsEnabled = true;
    _socket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = _socket!.receive();
      if (datagram == null) return;
      unawaited(_handleAnnouncement(datagram));
    });
    _announcementTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_sendAnnouncement()),
    );
  }

  Future<void> _sendAnnouncement() async {
    if (!_isAdvertising && !_isDiscovering) return;
    final payload = await _announcementPayload();
    _socket?.send(payload, InternetAddress('255.255.255.255'), discoveryPort);

    // Some Android access points isolate or drop broadcast packets. Probe the
    // common local /24 directly so discovery still works on those networks.
    if (!_isDiscovering) return;
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final octets = address.address.split('.');
        if (octets.length != 4) continue;
        final prefix = octets.sublist(0, 3).join('.');
        for (var host = 1; host < 255; host++) {
          if ('$prefix.$host' == address.address) continue;
          _socket?.send(payload, InternetAddress('$prefix.$host'), discoveryPort);
        }
      }
    }
  }

  Future<List<int>> _announcementPayload() async {
    final deviceName = await _getDeviceName();
    return utf8.encode(jsonEncode({
      'id': _deviceId,
      'name': deviceName,
      'platform': _platform.name,
      'port': transferPort,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (_activeEventId != null)
        'event': {'id': _activeEventId, 'name': _activeEventName, 'expires': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch},
    }));
  }

  Future<String> _getDeviceName() async {
    if (_deviceName != null) return _deviceName!;
    try {
      final nativeName = await const MethodChannel('flowsend/device')
          .invokeMethod<String>('deviceName');
      if (nativeName != null && nativeName.trim().isNotEmpty) {
        return _deviceName = nativeName.trim();
      }
    } on Object {
      // Use the hostname on platforms without the native device-name channel.
    }
    return _deviceName = Platform.localHostname;
  }

  Future<void> _handleAnnouncement(Datagram datagram) async {
    try {
      final json = jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
      final id = json['id'] as String?;
      if (id == null || id == _deviceId) return;
      final device = DiscoveredDevice(
        id: id,
        name: json['name'] as String? ?? 'FlowSend device',
        platform: _parsePlatform(json['platform'] as String?),
        status: DeviceStatus.nearby,
        address: datagram.address.address,
        port: json['port'] as int? ?? transferPort,
        signalStrength: 0.8,
        protocolInfo: 'FlowSend LAN · Local network',
        lastSeen: DateTime.now(),
      );
      _knownDevices[id] = device;
      _controller.add(List.unmodifiable(_knownDevices.values));
      if (_isAdvertising || _activeEventId != null) {
        final response = await _announcementPayload();
        _socket?.send(response, datagram.address, discoveryPort);
      }
      final event = json['event'];
      if (event is Map<String, dynamic> && event['id'] is String && event['name'] is String) {
        final expires = event['expires'] as int? ?? 0;
        if (expires > DateTime.now().millisecondsSinceEpoch) {
          _eventController.add(NearbyEventAnnouncement(
            eventId: event['id'] as String,
            eventName: event['name'] as String,
            device: device,
          ));
        }
      }
    } on Object {
      // Ignore unrelated UDP traffic on the discovery port.
    }
  }

  DevicePlatform get _platform {
    return switch (Platform.operatingSystem) {
      'android' => DevicePlatform.android,
      'ios' => DevicePlatform.ios,
      'macos' => DevicePlatform.macos,
      'windows' => DevicePlatform.windows,
      'linux' => DevicePlatform.linux,
      _ => DevicePlatform.unknown,
    };
  }

  DevicePlatform _parsePlatform(String? value) {
    for (final platform in DevicePlatform.values) {
      if (platform.name == value) return platform;
    }
    return DevicePlatform.unknown;
  }

  void _stopIfUnused() {
    if (_isDiscovering || _isAdvertising || _activeEventId != null) return;
    _announcementTimer?.cancel();
    _announcementTimer = null;
    _socket?.close();
    _socket = null;
  }

  @override
  void dispose() {
    _isDiscovering = false;
    _isAdvertising = false;
    _announcementTimer?.cancel();
    _socket?.close();
    _controller.close();
    _eventController.close();
  }
}

class NearbyEventAnnouncement {
  const NearbyEventAnnouncement({required this.eventId, required this.eventName, required this.device});
  final String eventId;
  final String eventName;
  final DiscoveredDevice device;
}
