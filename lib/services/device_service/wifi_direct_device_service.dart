import 'dart:async';
import 'dart:io';

import '../../models/discovered_device.dart';
import 'device_service.dart';
import '../connection_service/wifi_direct_channel.dart';

/// Discovers nearby FlowSend peers via Android Wi-Fi Direct (P2P).
///
/// This is only used by [SmartDeviceService] to fill in devices that are
/// nearby but NOT reachable on the current Wi-Fi/LAN — it never replaces or
/// alters [LanDeviceService].
class WifiDirectDeviceService implements DeviceService {
  final _controller = StreamController<List<DiscoveredDevice>>.broadcast();
  final Map<String, DiscoveredDevice> _known = {};
  StreamSubscription<List<WifiDirectPeer>>? _peerSubscription;
  bool _isDiscovering = false;

  @override
  Stream<List<DiscoveredDevice>> get devicesStream => _controller.stream;

  @override
  List<DiscoveredDevice> get devices => List.unmodifiable(_known.values);

  @override
  bool get isDiscovering => _isDiscovering;

  Future<bool> get isSupported => WifiDirectChannel.instance.isSupported();

  @override
  Future<void> startDiscovery() async {
    if (!Platform.isAndroid) return;
    if (!await isSupported) return;
    _isDiscovering = true;
    _peerSubscription ??= WifiDirectChannel.instance.peersStream.listen(_onPeers);
    try {
      await WifiDirectChannel.instance.startDiscovery();
    } on Object {
      // Discovery failing (radio off, busy) is surfaced as "no P2P peers".
    }
  }

  void _onPeers(List<WifiDirectPeer> peers) {
    _known
      ..clear()
      ..addEntries(peers.map((peer) => MapEntry(
            'p2p-${peer.address}',
            DiscoveredDevice(
              id: 'p2p-${peer.address}',
              name: peer.name,
              platform: DevicePlatform.android,
              status: DeviceStatus.nearby,
              signalStrength: 0.6,
              protocolInfo: 'Wi-Fi Direct · No shared network',
              lastSeen: DateTime.now(),
              connectionMethod: ConnectionMethod.wifiDirect,
              p2pDeviceAddress: peer.address,
            ),
          )));
    _controller.add(List.unmodifiable(_known.values));
  }

  @override
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    try {
      await WifiDirectChannel.instance.stopDiscovery();
    } on Object {
      // Ignore — nothing to clean up if discovery never started.
    }
  }

  @override
  Future<void> startAdvertising() async {
    // Wi-Fi Direct peers advertise themselves automatically once discoverable;
    // there is no separate advertise call on Android's P2P API.
  }

  @override
  Future<void> stopAdvertising() async {}

  @override
  void dispose() {
    _peerSubscription?.cancel();
    _controller.close();
  }
}
