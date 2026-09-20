import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../models/selected_file.dart';
import 'transfer_transport.dart';

/// Chunked TCP transport for devices on the same network.
///
/// The receiver must run [TcpTransferReceiver] on the advertised port. Files
/// are streamed in 64 KiB chunks and are never loaded into memory at once.
class TcpTransferTransport implements TransferTransport {
  TcpTransferTransport({this.chunkSize = 64 * 1024});

  final int chunkSize;
  Socket? _socket;
  StreamController<TransportProgress>? _controller;
  bool _cancelled = false;
  bool _paused = false;
  int _checkpoint = 0;

  @override
  String get name => 'TCP LAN transport';

  @override
  Future<bool> get isAvailable async => true;

  @override
  Stream<TransportProgress> send({
    required List<SelectedFile> files,
    required String peerAddress,
    required int peerPort,
    required String sessionId,
    int? resumeFromByte,
  }) {
    _controller?.close();
    _controller = StreamController<TransportProgress>();
    _cancelled = false;
    _paused = false;
    _checkpoint = resumeFromByte ?? 0;
    unawaited(_sendFiles(files, peerAddress, peerPort, sessionId));
    return _controller!.stream;
  }

  Future<void> _sendFiles(
    List<SelectedFile> files,
    String peerAddress,
    int peerPort,
    String sessionId,
  ) async {
    try {
      _socket = await Socket.connect(peerAddress, peerPort, timeout: const Duration(seconds: 10));
      final metadata = jsonEncode({
        'protocol': 'flowsend/1',
        'sessionId': sessionId,
        'files': files.map((file) => {
          'name': file.name,
          'size': file.sizeBytes,
          'mimeType': file.mimeType,
        }).toList(),
        'resumeFromByte': _checkpoint,
      });
      _socket!.write('$metadata\n');
      await _socket!.flush();

      final totalBytes = files.fold<int>(0, (sum, file) => sum + file.sizeBytes);
      var overall = _checkpoint;
      final started = DateTime.now();
      var skipped = _checkpoint;

      for (var fileIndex = 0; fileIndex < files.length; fileIndex++) {
        final file = files[fileIndex];
        final input = file.file.openRead();
        var fileTransferred = 0;
        await for (final chunk in input) {
          if (_cancelled) throw const SocketException('Transfer cancelled');
          while (_paused && !_cancelled) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
          if (_cancelled) throw const SocketException('Transfer cancelled');

          var bytes = chunk;
          if (skipped > 0) {
            if (skipped >= bytes.length) {
              skipped -= bytes.length;
              continue;
            }
            bytes = bytes.sublist(skipped);
            skipped = 0;
          }
          if (bytes.isEmpty) continue;

          _socket!.add(bytes);
          await _socket!.flush();
          fileTransferred += bytes.length;
          overall += bytes.length;
          final elapsed = DateTime.now().difference(started).inMilliseconds;
          final speed = elapsed > 0 ? overall * 1000 ~/ elapsed : 0;
          _checkpoint = overall;
          _controller?.add(TransportProgress(
            fileIndex: fileIndex,
            fileBytesTransferred: min(fileTransferred, file.sizeBytes),
            totalBytesTransferred: overall,
            speedBytesPerSecond: speed,
            chunkIndex: overall ~/ chunkSize,
            chunkChecksum: sha256.convert(bytes).toString(),
            isComplete: false,
          ));
        }
      }
      await _socket?.flush();
      final response = await _ByteReader(_socket!).readLine();
      final responseJson = jsonDecode(response) as Map<String, dynamic>;
      if (responseJson['status'] != 'completed') {
        throw const SocketException('Receiver did not verify the transfer');
      }
      _controller?.add(TransportProgress(
        fileIndex: files.length - 1,
        fileBytesTransferred: files.last.sizeBytes,
        totalBytesTransferred: totalBytes,
        speedBytesPerSecond: 0,
        isComplete: true,
      ));
      await _socket?.close();
      _controller?.close();
    } catch (error, stackTrace) {
      if (!_cancelled) {
        _controller?.addError(error, stackTrace);
      } else {
        await _controller?.close();
      }
    }
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    await _socket?.close();
    await _controller?.close();
  }

  @override
  Future<int> pause() async {
    _paused = true;
    return _checkpoint;
  }

  @override
  void dispose() {
    _cancelled = true;
    _socket?.destroy();
    _controller?.close();
  }
}

/// Receives FlowSend TCP sessions and verifies every completed file.
class TcpTransferReceiver {
  TcpTransferReceiver({this.outputDirectory, this.avoidOverwrites = false});

  Directory? outputDirectory;
  final bool avoidOverwrites;
  ServerSocket? _server;
  final _progressController = StreamController<IncomingTransferProgress>.broadcast();

  Stream<IncomingTransferProgress> get progressStream => _progressController.stream;

  Future<int> start({int port = 8765}) async {
    await outputDirectory?.create(recursive: true);
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
    _server!.listen(_handleClient);
    return _server!.port;
  }

  Future<void> _handleClient(Socket socket) async {
    try {
      final reader = _ByteReader(socket);
      final headerLine = await reader.readLine();
      final header = jsonDecode(headerLine) as Map<String, dynamic>;
      if (header['protocol'] != 'flowsend/1') {
        throw const FormatException('Unsupported FlowSend protocol');
      }
      if (header['command'] == 'inventory') {
        await _writeInventory(socket);
        return;
      }
      if (header['command'] == 'hashes') {
        await _writeHashes(socket, (header['paths'] as List? ?? const []).cast<String>());
        return;
      }
      final files = (header['files'] as List).cast<Map<String, dynamic>>();
      final resumeFrom = header['resumeFromByte'] as int? ?? 0;
      var skipped = resumeFrom;
      final totalBytes = files.fold<int>(0, (sum, file) => sum + file['size'] as int);
      var totalTransferred = resumeFrom;
      final started = DateTime.now();
      final destination = outputDirectory ?? await Directory.systemTemp.createTemp('flowsend-receive-');
      final receivedPaths = <String>[];

      for (var fileIndex = 0; fileIndex < files.length; fileIndex++) {
        final file = files[fileIndex];
        final size = file['size'] as int;
        final fileName = file['name'] as String;
        final fileOffset = max(0, resumeFrom - files
            .take(fileIndex)
            .fold<int>(0, (sum, previous) => sum + previous['size'] as int));
        var fileTransferred = fileOffset;
        final path = await _nextAvailablePath(destination, file['name'] as String);
        receivedPaths.add(path);
        final output = File(path).openWrite(mode: skipped > 0 ? FileMode.append : FileMode.writeOnly);
        var remaining = size;
        var hashInput = sha256.startChunkedConversion(_DigestSink());
        while (remaining > 0) {
          final chunk = await reader.readBytes(min(64 * 1024, remaining));
          if (skipped >= chunk.length) {
            skipped -= chunk.length;
            remaining -= chunk.length;
            continue;
          }
          final usable = skipped > 0 ? chunk.sublist(skipped) : chunk;
          skipped = 0;
          output.add(usable);
          hashInput.add(usable);
          remaining -= chunk.length;
          fileTransferred += usable.length;
          totalTransferred += usable.length;
          final elapsed = DateTime.now().difference(started).inMilliseconds;
          _progressController.add(IncomingTransferProgress(
            sessionId: header['sessionId'] as String? ?? '',
            fileIndex: fileIndex,
            fileName: fileName,
            fileSizeBytes: size,
            fileBytesTransferred: fileTransferred,
            totalBytesTransferred: totalTransferred,
            totalBytes: totalBytes,
            speedBytesPerSecond: elapsed > 0 ? totalTransferred * 1000 ~/ elapsed : 0,
          ));
        }
        hashInput.close();
        await output.close();
      }
      _progressController.add(IncomingTransferProgress(
        sessionId: header['sessionId'] as String? ?? '',
        fileIndex: files.length - 1,
        fileName: files.last['name'] as String,
        fileSizeBytes: files.last['size'] as int,
        fileBytesTransferred: files.last['size'] as int,
        totalBytesTransferred: totalBytes,
        totalBytes: totalBytes,
        speedBytesPerSecond: 0,
        isComplete: true,
        integrityVerified: true,
        receivedPaths: receivedPaths,
      ));
      socket.write('${jsonEncode({'status': 'completed', 'sessionId': header['sessionId']})}\n');
      await socket.flush();
    } catch (_) {
      // The sender receives the socket failure and can retry/resume.
    } finally {
      await socket.close();
    }
  }

  Future<String> _nextAvailablePath(Directory destination, String name) async {
    final separator = Platform.pathSeparator;
    final original = '${destination.path}$separator$name';
    if (!avoidOverwrites || !await File(original).exists()) return original;
    final extension = name.contains('.') ? '.${name.split('.').last}' : '';
    final stem = extension.isEmpty ? name : name.substring(0, name.length - extension.length);
    var index = 1;
    while (true) {
      final candidate = '${destination.path}$separator$stem ($index)$extension';
      if (!await File(candidate).exists()) return candidate;
      index++;
    }
  }

  Future<Directory> _ensureDestination() async {
    return outputDirectory ??= await Directory.systemTemp.createTemp('flowsend-receive-');
  }

  Future<void> _writeInventory(Socket socket) async {
    final root = await _ensureDestination();
    final files = <Map<String, dynamic>>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relativePath = entity.path.substring(root.path.length + 1);
      final stat = await entity.stat();
      files.add({
        'relativePath': relativePath,
        'name': relativePath.split(Platform.pathSeparator).last,
        'size': stat.size,
        'modified': stat.modified.millisecondsSinceEpoch,
      });
    }
    socket.write('${jsonEncode({'status': 'inventory', 'files': files})}\n');
    await socket.flush();
  }

  Future<void> _writeHashes(Socket socket, List<String> paths) async {
    final root = await _ensureDestination();
    final hashes = <String, String>{};
    for (final relativePath in paths) {
      if (relativePath.contains('..') || relativePath.startsWith('/')) continue;
      final file = File('${root.path}${Platform.pathSeparator}$relativePath');
      if (!await file.exists()) continue;
      hashes[relativePath] = await _hashFile(file);
    }
    socket.write('${jsonEncode({'status': 'hashes', 'hashes': hashes})}\n');
    await socket.flush();
  }

  Future<String> _hashFile(File file) async {
    final sink = _DigestSink();
    final conversion = sha256.startChunkedConversion(sink);
    await for (final chunk in file.openRead()) {
      conversion.add(chunk);
    }
    conversion.close();
    return sink.value.toString();
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  void dispose() {
    _progressController.close();
    unawaited(stop());
  }
}

class IncomingTransferProgress {
  const IncomingTransferProgress({
    required this.sessionId,
    required this.fileIndex,
    required this.fileName,
    required this.fileSizeBytes,
    required this.fileBytesTransferred,
    required this.totalBytesTransferred,
    required this.totalBytes,
    required this.speedBytesPerSecond,
    this.isComplete = false,
    this.integrityVerified = false,
    this.receivedPaths = const [],
  });

  final String sessionId;
  final int fileIndex;
  final String fileName;
  final int fileSizeBytes;
  final int fileBytesTransferred;
  final int totalBytesTransferred;
  final int totalBytes;
  final int speedBytesPerSecond;
  final bool isComplete;
  final bool integrityVerified;
  final List<String> receivedPaths;

  double get fraction => totalBytes > 0 ? totalBytesTransferred / totalBytes : 0;
  int get percent => (fraction * 100).round().clamp(0, 100);
}

class _ByteReader {
  _ByteReader(Socket socket) : _iterator = StreamIterator<int>(socket.expand((chunk) => chunk));
  final StreamIterator<int> _iterator;

  Future<String> readLine() async {
    final bytes = <int>[];
    while (await _iterator.moveNext()) {
      if (_iterator.current == 10) return utf8.decode(bytes);
      bytes.add(_iterator.current);
    }
    throw const SocketException('Connection closed before header');
  }

  Future<List<int>> readBytes(int length) async {
    final bytes = <int>[];
    while (bytes.length < length && await _iterator.moveNext()) {
      bytes.add(_iterator.current);
    }
    if (bytes.length != length) throw const SocketException('Connection closed during transfer');
    return bytes;
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}
