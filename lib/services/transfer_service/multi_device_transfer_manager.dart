import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/discovered_device.dart';
import '../../models/selected_file.dart';
import '../../models/transfer_session.dart';
import 'transfer_service.dart';

enum MultiDeviceItemState {
  queued,
  connecting,
  transferring,
  paused,
  interrupted,
  completed,
  failed,
  cancelled,
}

class MultiDeviceTransferItem {
  MultiDeviceTransferItem({required this.device});

  final DiscoveredDevice device;
  TransferService? service;
  MultiDeviceItemState state = MultiDeviceItemState.queued;
  String? errorMessage;
  bool countedAsActive = false;
  bool countedAsFinished = false;
  int attempts = 0;

  TransferSession? get session => service?.activeSession;

  int get transferredBytes => session?.overallTransferredBytes ?? 0;
  int get totalBytes => session?.totalBytes ?? 0;
  int get speedBytesPerSecond => session?.speedBytesPerSecond ?? 0;
  int get percent => session?.overallPercent ?? 0;
}

/// Orchestrates independent real transfers to multiple receivers.
/// Each receiver owns its own [TransferService], so one failure cannot stop
/// another device. A small concurrency cap keeps storage and CPU bounded.
class MultiDeviceTransferManager extends ChangeNotifier {
  MultiDeviceTransferManager({this.maxConcurrent = 2});

  final int maxConcurrent;
  final List<MultiDeviceTransferItem> items = [];
  final List<SelectedFile> files = [];
  final Map<String, List<SelectedFile>> filesByDevice = {};
  final Set<String> _queuedIds = {};
  int _activeCount = 0;
  bool _started = false;
  bool _cancelled = false;

  bool get isStarted => _started;
  bool get isComplete => items.isNotEmpty && items.every(
        (item) => item.state == MultiDeviceItemState.completed,
      );
  bool get hasFailures => items.any(
        (item) => item.state == MultiDeviceItemState.failed,
      );
  bool get isPartiallyComplete => isComplete ||
      (items.any((item) => item.state == MultiDeviceItemState.completed) && hasFailures);

  int get totalBytes => files.fold(0, (sum, file) => sum + file.sizeBytes);
  int get aggregateTransferredBytes => items.fold(
        0,
        (sum, item) => sum + item.transferredBytes,
      );
  int get aggregateTotalBytes => items.fold(
        0,
        (sum, item) => sum + _filesFor(item).fold(0, (fileSum, file) => fileSum + file.sizeBytes),
      );
  double get overallFraction => aggregateTotalBytes == 0
      ? 0
      : aggregateTransferredBytes / aggregateTotalBytes;
  int get overallPercent => (overallFraction * 100).round().clamp(0, 100);

  void configure({
    required List<SelectedFile> selectedFiles,
    required List<DiscoveredDevice> devices,
    Map<String, List<SelectedFile>>? selectedFilesByDevice,
  }) {
    if (_started) return;
    files
      ..clear()
      ..addAll(selectedFiles);
    filesByDevice
      ..clear()
      ..addAll(selectedFilesByDevice ?? const {});
    items
      ..clear()
      ..addAll(devices.map((device) => MultiDeviceTransferItem(device: device)));
    notifyListeners();
  }

  void start() {
    if (_started || items.isEmpty || files.isEmpty) return;
    _started = true;
    _cancelled = false;
    _queueNext();
    notifyListeners();
  }

  void _queueNext() {
    if (_cancelled) return;
    while (_activeCount < maxConcurrent) {
      final next = items.cast<MultiDeviceTransferItem?>().firstWhere(
        (item) => item != null &&
            item.state == MultiDeviceItemState.queued &&
            !_queuedIds.contains(item.device.id),
        orElse: () => null,
      );
      if (next == null) break;
      _queuedIds.add(next.device.id);
      _launch(next);
    }
  }

  Future<void> _launch(MultiDeviceTransferItem item) async {
    _activeCount++;
    item.countedAsActive = true;
    item.attempts++;
    item.service?.dispose();
    final service = TransferService();
    item.service = service;
    service.addListener(() => _onServiceChanged(item));
    notifyListeners();

    try {
      await service.startTransfer(files: _filesFor(item), targetDevice: item.device);
      _syncState(item);
      _onServiceChanged(item);
    } catch (error) {
      item.errorMessage = error.toString();
      item.state = MultiDeviceItemState.failed;
      _finishActive(item);
    }
  }

    List<SelectedFile> _filesFor(MultiDeviceTransferItem item) =>
      filesByDevice[item.device.id] ?? files;

    int bytesFor(String deviceId) => (filesByDevice[deviceId] ?? files)
      .fold(0, (sum, file) => sum + file.sizeBytes);

  void _onServiceChanged(MultiDeviceTransferItem item) {
    _syncState(item);
    final session = item.session;
    if (session != null && session.isTerminal) {
      _finishActive(item);
    }
    notifyListeners();
  }

  void _syncState(MultiDeviceTransferItem item) {
    final state = item.service?.state;
    item.state = switch (state) {
      TransferState.connecting => MultiDeviceItemState.connecting,
      TransferState.transferring => MultiDeviceItemState.transferring,
      TransferState.paused => MultiDeviceItemState.paused,
      TransferState.interrupted || TransferState.resuming => MultiDeviceItemState.interrupted,
      TransferState.completed => MultiDeviceItemState.completed,
      TransferState.failed => MultiDeviceItemState.failed,
      TransferState.cancelled => MultiDeviceItemState.cancelled,
      _ => item.state,
    };
    item.errorMessage ??= item.session?.errorMessage;
  }

  void _finishActive(MultiDeviceTransferItem item) {
    if (!item.countedAsActive || item.countedAsFinished) return;
    item.countedAsFinished = true;
    item.countedAsActive = false;
    _activeCount = (_activeCount - 1).clamp(0, maxConcurrent);
    _queuedIds.remove(item.device.id);
    _queueNext();
  }

  Future<void> retry(String deviceId) async {
    if (!_started || _cancelled) return;
    final item = items.cast<MultiDeviceTransferItem?>().firstWhere(
      (candidate) => candidate?.device.id == deviceId,
      orElse: () => null,
    );
    if (item == null || item.state != MultiDeviceItemState.failed) return;
    item.state = MultiDeviceItemState.queued;
    item.errorMessage = null;
    item.countedAsFinished = false;
    _queuedIds.remove(item.device.id);
    _queueNext();
    notifyListeners();
  }

  Future<void> retryFailed() async {
    for (final item in items.where(
      (item) => item.state == MultiDeviceItemState.failed,
    )) {
      await retry(item.device.id);
    }
  }

  Future<void> cancelAll() async {
    _cancelled = true;
    for (final item in items) {
      await item.service?.cancel();
      if (item.state != MultiDeviceItemState.completed) {
        item.state = MultiDeviceItemState.cancelled;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final item in items) {
      item.service?.dispose();
    }
    super.dispose();
  }
}
