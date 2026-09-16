import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowsend/models/discovered_device.dart';
import 'package:flowsend/models/selected_file.dart';
import 'package:flowsend/services/network_service/tcp_transfer_transport.dart';
import 'package:flowsend/services/transfer_service/multi_device_transfer_manager.dart';

void main() {
  test('manager transfers independently to two real receivers', () async {
    final sourceDirectory = await Directory.systemTemp.createTemp('flowsend-multi-source-');
    final destinationA = await Directory.systemTemp.createTemp('flowsend-multi-a-');
    final destinationB = await Directory.systemTemp.createTemp('flowsend-multi-b-');
    final source = File('${sourceDirectory.path}/multi.txt');
    await source.writeAsString('multi-device payload');

    final receiverA = TcpTransferReceiver(outputDirectory: destinationA);
    final receiverB = TcpTransferReceiver(outputDirectory: destinationB);
    final portA = await receiverA.start(port: 0);
    final portB = await receiverB.start(port: 0);
    final file = SelectedFile(
      id: 'multi-file',
      name: 'multi.txt',
      path: source.path,
      sizeBytes: await source.length(),
      mimeType: 'text/plain',
      lastModified: DateTime.now(),
    );
    final devices = [
      const DiscoveredDevice(
        id: 'receiver-a',
        name: 'Receiver A',
        platform: DevicePlatform.android,
        status: DeviceStatus.nearby,
        address: '127.0.0.1',
        port: 0,
      ),
      const DiscoveredDevice(
        id: 'receiver-b',
        name: 'Receiver B',
        platform: DevicePlatform.android,
        status: DeviceStatus.nearby,
        address: '127.0.0.1',
        port: 0,
      ),
    ];
    final manager = MultiDeviceTransferManager(maxConcurrent: 2);
    manager.configure(selectedFiles: [file], devices: [
      devices[0].copyWith(port: portA),
      devices[1].copyWith(port: portB),
    ]);
    manager.start();

    await _waitUntil(() => manager.isComplete);

    expect(await File('${destinationA.path}/multi.txt').readAsString(), 'multi-device payload');
    expect(await File('${destinationB.path}/multi.txt').readAsString(), 'multi-device payload');
    expect(manager.overallPercent, 100);

    manager.dispose();
    await receiverA.stop();
    await receiverB.stop();
    await sourceDirectory.delete(recursive: true);
    await destinationA.delete(recursive: true);
    await destinationB.delete(recursive: true);
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  expect(condition(), isTrue, reason: 'Timed out waiting for multi-device transfer');
}
