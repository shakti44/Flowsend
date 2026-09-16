import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowsend/models/selected_file.dart';
import 'package:flowsend/services/network_service/tcp_transfer_transport.dart';

void main() {
  test('TCP transport streams a file to the receiver', () async {
    final sourceDirectory = await Directory.systemTemp.createTemp('flowsend-test-source-');
    final destinationDirectory = await Directory.systemTemp.createTemp('flowsend-test-destination-');
    final source = File('${sourceDirectory.path}/payload.txt');
    await source.writeAsString('FlowSend real TCP payload');

    final receiver = TcpTransferReceiver(outputDirectory: destinationDirectory);
    final port = await receiver.start(port: 0);
    final transport = TcpTransferTransport(chunkSize: 4);
    final selectedFile = SelectedFile(
      id: 'test-file',
      name: 'payload.txt',
      path: source.path,
      sizeBytes: await source.length(),
      mimeType: 'text/plain',
      lastModified: DateTime.now(),
    );

    final progress = <int>[];
    await transport
        .send(
          files: [selectedFile],
          peerAddress: InternetAddress.loopbackIPv4.address,
          peerPort: port,
          sessionId: 'test-session',
        )
        .forEach((event) => progress.add(event.totalBytesTransferred));

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(progress, isNotEmpty);
    expect(progress.last, selectedFile.sizeBytes);
    expect(await File('${destinationDirectory.path}/payload.txt').readAsString(), 'FlowSend real TCP payload');

    transport.dispose();
    await receiver.stop();
    await sourceDirectory.delete(recursive: true);
    await destinationDirectory.delete(recursive: true);
  });
}
