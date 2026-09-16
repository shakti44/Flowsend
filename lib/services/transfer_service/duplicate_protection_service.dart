import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../models/discovered_device.dart';
import '../../models/duplicate_analysis.dart';
import '../../models/selected_file.dart';

class DuplicateProtectionService {
  DuplicateProtectionService({this.largeFileThresholdBytes = 1 << 30});

  final int largeFileThresholdBytes;

  Future<DeviceDuplicateAnalysis> analyze({
    required List<SelectedFile> files,
    required DiscoveredDevice device,
    void Function(int completed, int total)? onProgress,
  }) async {
    final inventory = await _requestInventory(device);
    final sameSize = <SelectedFile, List<RemoteFileInfo>>{};
    final sameName = <SelectedFile, List<RemoteFileInfo>>{};

    for (final file in files) {
      sameSize[file] = inventory.where((remote) => remote.sizeBytes == file.sizeBytes).toList();
      sameName[file] = inventory.where((remote) => remote.name == file.name).toList();
    }

    final candidates = sameSize.values.expand((items) => items).toSet().toList();
    final receiverHashes = candidates.isEmpty
        ? <String, String>{}
        : await _requestHashes(device, candidates.map((item) => item.relativePath).toList());

    final results = <DuplicateFileAnalysis>[];
    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final sizeMatches = sameSize[file]!;
      final nameMatches = sameName[file]!;
      var status = file.sizeBytes >= largeFileThresholdBytes
          ? DuplicateStatus.largeFile
          : DuplicateStatus.newFile;
      var remoteMatches = <RemoteFileInfo>[];

      if (sizeMatches.isNotEmpty) {
        final senderHash = await _hash(file.file);
        remoteMatches = sizeMatches;
        final hasExactMatch = sizeMatches.any(
          (remote) => receiverHashes[remote.relativePath] == senderHash,
        );
        if (hasExactMatch) {
          status = DuplicateStatus.exactDuplicate;
        } else if (nameMatches.isNotEmpty) {
          status = DuplicateStatus.possibleDuplicate;
        }
      } else if (nameMatches.isNotEmpty) {
        status = DuplicateStatus.possibleDuplicate;
        remoteMatches = nameMatches;
      }

      results.add(DuplicateFileAnalysis(file: file, status: status, remoteMatches: remoteMatches));
      onProgress?.call(index + 1, files.length);
    }

    return DeviceDuplicateAnalysis(deviceName: device.name, files: results);
  }

  Future<List<RemoteFileInfo>> _requestInventory(DiscoveredDevice device) async {
    final response = await _request(device, {
      'protocol': 'flowsend/1',
      'command': 'inventory',
    });
    return (response['files'] as List? ?? const [])
        .map((item) {
          final json = item as Map<String, dynamic>;
          return RemoteFileInfo(
            relativePath: json['relativePath'] as String,
            name: json['name'] as String,
            sizeBytes: json['size'] as int,
            modifiedAt: DateTime.fromMillisecondsSinceEpoch(json['modified'] as int),
          );
        })
        .toList(growable: false);
  }

  Future<Map<String, String>> _requestHashes(
    DiscoveredDevice device,
    List<String> paths,
  ) async {
    final response = await _request(device, {
      'protocol': 'flowsend/1',
      'command': 'hashes',
      'paths': paths,
    });
    return (response['hashes'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  Future<Map<String, dynamic>> _request(
    DiscoveredDevice device,
    Map<String, dynamic> payload,
  ) async {
    final address = device.address;
    final port = device.port;
    if (address == null || port == null) {
      throw const SocketException('Device has no reachable transfer address');
    }
    final socket = await Socket.connect(address, port, timeout: const Duration(seconds: 10));
    try {
      socket.write('${jsonEncode(payload)}\n');
      await socket.flush();
      final line = await _readLine(socket);
      return jsonDecode(line) as Map<String, dynamic>;
    } finally {
      await socket.close();
    }
  }

  Future<String> _readLine(Socket socket) async {
    final iterator = StreamIterator<int>(socket.expand((chunk) => chunk));
    final bytes = <int>[];
    while (await iterator.moveNext()) {
      if (iterator.current == 10) return utf8.decode(bytes);
      bytes.add(iterator.current);
    }
    throw const SocketException('Receiver closed the preflight connection');
  }

  Future<String> _hash(File file) async {
    final sink = _DigestSink();
    final conversion = sha256.startChunkedConversion(sink);
    await for (final chunk in file.openRead()) {
      conversion.add(chunk);
    }
    conversion.close();
    return sink.value.toString();
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}
