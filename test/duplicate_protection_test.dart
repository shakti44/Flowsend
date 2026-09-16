import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowsend/models/discovered_device.dart';
import 'package:flowsend/models/duplicate_analysis.dart';
import 'package:flowsend/models/selected_file.dart';
import 'package:flowsend/services/network_service/tcp_transfer_transport.dart';
import 'package:flowsend/services/transfer_service/duplicate_protection_service.dart';

void main() {
  test('classifies exact, possible, and new files from real receiver data', () async {
    final sourceDirectory = await Directory.systemTemp.createTemp('flowsend-dup-source-');
    final receiverDirectory = await Directory.systemTemp.createTemp('flowsend-dup-receiver-');
    final exactReceiverFile = File('${receiverDirectory.path}/existing.txt');
    final possibleReceiverFile = File('${receiverDirectory.path}/photo.jpg');
    await exactReceiverFile.writeAsString('same bytes');
    await possibleReceiverFile.writeAsString('receiver version');

    final receiver = TcpTransferReceiver(outputDirectory: receiverDirectory);
    final port = await receiver.start(port: 0);
    final sameContentDifferentName = File('${sourceDirectory.path}/renamed.txt');
    final sameNameDifferentContent = File('${sourceDirectory.path}/photo.jpg');
    final newFile = File('${sourceDirectory.path}/new.txt');
    await sameContentDifferentName.writeAsString('same bytes');
    await sameNameDifferentContent.writeAsString('sender version');
    await newFile.writeAsString('new content');

    SelectedFile selected(File file) => SelectedFile(
          id: file.path,
          name: file.path.split('/').last,
          path: file.path,
          sizeBytes: file.lengthSync(),
          mimeType: 'text/plain',
          lastModified: DateTime.now(),
        );

    final result = await DuplicateProtectionService().analyze(
      files: [selected(sameContentDifferentName), selected(sameNameDifferentContent), selected(newFile)],
      device: DiscoveredDevice(
        id: 'receiver',
        name: 'Receiver',
        platform: DevicePlatform.android,
        status: DeviceStatus.nearby,
        address: '127.0.0.1',
        port: port,
      ),
    );

    expect(result.files[0].status, DuplicateStatus.exactDuplicate);
    expect(result.files[1].status, DuplicateStatus.possibleDuplicate);
    expect(result.files[2].status, DuplicateStatus.newFile);

    await receiver.stop();
    await sourceDirectory.delete(recursive: true);
    await receiverDirectory.delete(recursive: true);
  });
}
