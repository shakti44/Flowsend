import 'dart:async';

import '../../models/discovered_device.dart';
import 'device_service.dart';
import 'lan_device_service.dart';
import 'wifi_direct_device_service.dart';

/// Smart Connection discovery layer.
///
/// Merges the existing, unmodified [LanDeviceService] (same Wi-Fi) with
/// [WifiDirectDeviceService] (no common Wi-Fi) into a single device list so
/// the UI never needs to know which transport will end up being used.
///
/// Same-Wi-Fi devices always win: if a device is reachable over LAN it is
/// reported as [ConnectionMethod.lan] and Wi-Fi Direct is never involved for
/// that device, exactly as it worked before this layer was added.
class SmartDeviceService implements DeviceService {
  SmartDeviceService({LanDeviceService? lanDeviceService, WifiDirectDeviceService? wifiDirectDeviceService})
      : _lan = lanDeviceService ?? LanDeviceService(),
        _wifiDirect = wifiDirectDeviceService ?? WifiDirectDeviceService();

  final LanDeviceService _lan;
  final WifiDirectDeviceService _wifiDirect;

  final _controller = StreamController<List<DiscoveredDevice>>.broadcast();
  List<DiscoveredDevice> _lanDevices = const [];
  List<DiscoveredDevice> _wifiDirectDevices = const [];
  StreamSubscription<List<DiscoveredDevice>>? _lanSub;
  StreamSubscription<List<DiscoveredDevice>>? _wifiDirectSub;
  bool _isDiscovering = false;

  LanDeviceService get lan => _lan;

  Stream<NearbyEventAnnouncement> get eventStream => _lan.eventStream;

  @override
  Stream<List<DiscoveredDevice>> get devicesStream => _controller.stream;

  @override
  List<DiscoveredDevice> get devices => _merge();

  @override
  bool get isDiscovering => _isDiscovering;

  List<DiscoveredDevice> _merge() {
    final byName = <String, DiscoveredDevice>{};
    // LAN devices are the "easiest path" and always take priority.
    for (final device in _lanDevices) {
      byName[device.name] = device.connectionMethod == ConnectionMethod.lan
          ? device
          : device.copyWith(connectionMethod: ConnectionMethod.lan);
    }
    for (final device in _wifiDirectDevices) {
      if (byName.containsKey(device.name)) continue; // already reachable via LAN
      byName[device.name] = device;
    }
    return List.unmodifiable(byName.values);
  }

  void _emit() => _controller.add(_merge());

  @override
  Future<void> startDiscovery() async {
    _isDiscovering = true;
    _lanSub ??= _lan.devicesStream.listen((devices) {
      _lanDevices = devices;
      _emit();
    });
    _wifiDirectSub ??= _wifiDirect.devicesStream.listen((devices) {
      _wifiDirectDevices = devices;
      _emit();
    });
    await Future.wait([
      _lan.startDiscovery(),
      _wifiDirect.startDiscovery(),
    ]);
  }

  @override
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    await Future.wait([
      _lan.stopDiscovery(),
      _wifiDirect.stopDiscovery(),
    ]);
  }

  @override
  Future<void> startAdvertising() => _lan.startAdvertising();

  @override
  Future<void> stopAdvertising() => _lan.stopAdvertising();

  @override
  void dispose() {
    _lanSub?.cancel();
    _wifiDirectSub?.cancel();
    _lan.dispose();
    _wifiDirect.dispose();
    _controller.close();
  }
}
