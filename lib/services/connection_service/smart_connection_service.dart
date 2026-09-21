import 'dart:async';
import 'dart:io';

import '../../models/discovered_device.dart';
import '../connection_service/wifi_direct_channel.dart';

enum SmartConnectionFailureReason {
  timeout,
  rejected,
  deviceLost,
  unsupported,
  failed,
}

class SmartConnectionException implements Exception {
  SmartConnectionException(this.reason, this.message);
  final SmartConnectionFailureReason reason;
  final String message;

  @override
  String toString() => message;
}

enum SmartConnectionPhase { negotiating, connected, failed }

class SmartConnectionUpdate {
  const SmartConnectionUpdate(this.phase, this.method, {this.message});
  final SmartConnectionPhase phase;
  final ConnectionMethod method;
  final String? message;
}

/// Smart Connection layer: picks the best path to a discovered device and
/// hands back a [DiscoveredDevice] with a reachable `address`/`port` so the
/// existing, unmodified [TransferService]/[TcpTransferTransport] can take
/// over exactly like it already does for same-Wi-Fi transfers.
///
/// Same-Wi-Fi devices (already carrying an `address`) skip this negotiation
/// entirely — this class only does work for devices that need Wi-Fi Direct.
class SmartConnectionService {
  SmartConnectionService._();
  static final SmartConnectionService instance = SmartConnectionService._();

  static const _receiverPort = 8765;
  static const _connectTimeout = Duration(seconds: 25);

  StreamSubscription<WifiDirectStatusEvent>? _statusSub;
  bool _hasActiveP2pGroup = false;

  /// Resolves [device] to a connection-ready [DiscoveredDevice].
  ///
  /// Emits progress via [onUpdate]. Throws [SmartConnectionException] on
  /// timeout, rejection, the peer disappearing, or an unsupported/failed
  /// Wi-Fi Direct negotiation.
  Future<DiscoveredDevice> connect(
    DiscoveredDevice device, {
    void Function(SmartConnectionUpdate update)? onUpdate,
  }) async {
    // Already reachable on the same Wi-Fi/LAN — nothing to negotiate.
    if (device.connectionMethod != ConnectionMethod.wifiDirect || device.address != null) {
      onUpdate?.call(const SmartConnectionUpdate(SmartConnectionPhase.connected, ConnectionMethod.lan));
      return device.connectionMethod == ConnectionMethod.unknown
          ? device.copyWith(connectionMethod: ConnectionMethod.lan)
          : device;
    }

    if (!Platform.isAndroid) {
      throw SmartConnectionException(
        SmartConnectionFailureReason.unsupported,
        'Direct connection is only available between Android devices right now.',
      );
    }

    final peerAddress = device.p2pDeviceAddress;
    if (peerAddress == null) {
      throw SmartConnectionException(
        SmartConnectionFailureReason.deviceLost,
        '${device.name} is no longer nearby.',
      );
    }

    if (!await WifiDirectChannel.instance.isSupported()) {
      throw SmartConnectionException(
        SmartConnectionFailureReason.unsupported,
        'This device does not support Wi-Fi Direct.',
      );
    }

    onUpdate?.call(const SmartConnectionUpdate(SmartConnectionPhase.negotiating, ConnectionMethod.wifiDirect));

    final completer = Completer<String>();
    _statusSub?.cancel();
    _statusSub = WifiDirectChannel.instance.statusStream.listen((event) {
      if (completer.isCompleted) return;
      if (event.event == 'connectionInfo' && event.connected && event.groupOwnerAddress != null) {
        _hasActiveP2pGroup = true;
        completer.complete(event.groupOwnerAddress);
      }
    });

    try {
      await WifiDirectChannel.instance.connect(peerAddress);
    } on Object catch (error) {
      await _statusSub?.cancel();
      throw SmartConnectionException(
        SmartConnectionFailureReason.failed,
        'Could not start a direct connection to ${device.name}: $error',
      );
    }

    late final String groupOwnerAddress;
    try {
      groupOwnerAddress = await completer.future.timeout(_connectTimeout);
    } on TimeoutException {
      await WifiDirectChannel.instance.cancelConnect();
      await _statusSub?.cancel();
      throw SmartConnectionException(
        SmartConnectionFailureReason.timeout,
        '${device.name} did not respond to the connection request in time.',
      );
    } on Object {
      await _statusSub?.cancel();
      throw SmartConnectionException(
        SmartConnectionFailureReason.rejected,
        '${device.name} declined the connection.',
      );
    }

    await _statusSub?.cancel();
    onUpdate?.call(const SmartConnectionUpdate(SmartConnectionPhase.connected, ConnectionMethod.wifiDirect));

    return device.copyWith(
      address: groupOwnerAddress,
      port: _receiverPort,
      connectionMethod: ConnectionMethod.wifiDirect,
      status: DeviceStatus.connected,
    );
  }

  /// Tears down any temporary Wi-Fi Direct group created for the transfer.
  /// Safe/no-op for same-Wi-Fi transfers, which never create a P2P group and
  /// never touch the user's normal Wi-Fi connection.
  Future<void> cleanup() async {
    _statusSub?.cancel();
    _statusSub = null;
    if (!_hasActiveP2pGroup || !Platform.isAndroid) return;
    _hasActiveP2pGroup = false;
    try {
      await WifiDirectChannel.instance.disconnect();
    } on Object {
      // Best-effort cleanup only.
    }
  }
}
