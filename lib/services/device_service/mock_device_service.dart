import 'dart:async';
import '../../models/discovered_device.dart';
import 'device_service.dart';

/// ⚠️ DEVELOPMENT/TESTING ONLY — MockDeviceService
///
/// Provides a set of simulated nearby devices for UI development and testing.
/// This service does NOT perform real network discovery.
///
/// To use real discovery, implement [DeviceService] with:
/// - mDNS / Bonjour (local network)
/// - Wi-Fi Direct / P2P
/// - BLE advertisement
/// - NSD (Network Service Discovery on Android)
///
/// Clearly labelled so this is never confused with production discovery.
class MockDeviceService implements DeviceService {
  final _controller = StreamController<List<DiscoveredDevice>>.broadcast();
  final List<DiscoveredDevice> _devices = [];
  bool _isDiscovering = false;
  Timer? _discoveryTimer;

  static const _mockDevices = [
    DiscoveredDevice(
      id: 'mock-macbook-pro-001',
      name: 'MacBook Pro',
      platform: DevicePlatform.macos,
      status: DeviceStatus.connected,
      address: '192.168.1.100',
      port: 8765,
      signalStrength: 0.95,
      protocolInfo: 'macOS Sonoma · Strong (5GHz Direct)',
      isTrusted: true,
    ),
    DiscoveredDevice(
      id: 'mock-iphone-16-pro',
      name: 'iPhone 16 Pro',
      platform: DevicePlatform.ios,
      status: DeviceStatus.nearby,
      address: '192.168.1.101',
      port: 8765,
      signalStrength: 0.82,
      protocolInfo: 'iOS 18 · FlowLink & AirDrop Ready',
    ),
    DiscoveredDevice(
      id: 'mock-windows-pc-001',
      name: 'Studio Windows PC',
      platform: DevicePlatform.windows,
      status: DeviceStatus.available,
      address: '192.168.1.102',
      port: 8765,
      signalStrength: 0.65,
      protocolInfo: 'Windows 11 Pro · Local Subnet (LAN)',
    ),
  ];

  @override
  Stream<List<DiscoveredDevice>> get devicesStream => _controller.stream;

  @override
  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);

  @override
  bool get isDiscovering => _isDiscovering;

  @override
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    _isDiscovering = true;
    _devices.clear();

    // Simulate progressive device discovery
    var index = 0;
    _discoveryTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (index < _mockDevices.length) {
        _devices.add(_mockDevices[index].copyWith(lastSeen: DateTime.now()));
        _controller.add(List.unmodifiable(_devices));
        index++;
      } else {
        t.cancel();
      }
    });
  }

  @override
  Future<void> stopDiscovery() async {
    _discoveryTimer?.cancel();
    _isDiscovering = false;
  }

  @override
  Future<void> startAdvertising() async {
    // Mock: no-op in development mode
    assert(
      true,
      'MockDeviceService.startAdvertising() is a no-op in development mode.',
    );
  }

  @override
  Future<void> stopAdvertising() async {
    // Mock: no-op in development mode
  }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _controller.close();
  }
}
