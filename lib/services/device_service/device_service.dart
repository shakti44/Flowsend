import '../../models/discovered_device.dart';

/// Abstract interface for device discovery.
/// The architecture allows real discovery (Wi-Fi Direct, mDNS, BLE)
/// to be plugged in without changing the UI.
abstract class DeviceService {
  /// Stream of discovered devices. Emits an updated full list
  /// each time a device is found, lost, or updates its state.
  Stream<List<DiscoveredDevice>> get devicesStream;

  /// Current snapshot of discovered devices.
  List<DiscoveredDevice> get devices;

  /// Start scanning for nearby devices.
  Future<void> startDiscovery();

  /// Stop scanning.
  Future<void> stopDiscovery();

  /// Whether discovery is currently active.
  bool get isDiscovering;

  /// Advertise this device so other FlowSend instances can find it.
  Future<void> startAdvertising();

  /// Stop advertising.
  Future<void> stopAdvertising();

  /// Clean up resources.
  void dispose();
}
