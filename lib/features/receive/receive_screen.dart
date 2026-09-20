import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_spacing.dart';
import '../../services/network_service/tcp_transfer_transport.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../routes/app_router.dart';
import '../../services/device_service/lan_device_service.dart';

/// Receive Screen — stub for Phase 2.
class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final _receiver = TcpTransferReceiver();
  final _deviceService = LanDeviceService();
  int? _port;
  Object? _error;
  IncomingTransferProgress? _progress;
  List<String> _receivedPaths = const [];
  StreamSubscription<IncomingTransferProgress>? _progressSubscription;
  StreamSubscription<NearbyEventAnnouncement>? _eventSubscription;
  final _seenEventIds = <String>{};

  @override
  void initState() {
    super.initState();
    _progressSubscription = _receiver.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          _receivedPaths = progress.receivedPaths;
        });
      }
    });
    _eventSubscription = _deviceService.eventStream.listen(_showNearbyEvent);
    _startReceiver();
  }

  Future<void> _startReceiver() async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      _receiver.outputDirectory = Directory(
        '${documents.path}${Platform.pathSeparator}received',
      );
      final port = await _receiver.start();
      await _deviceService.startAdvertising();
      if (mounted) setState(() => _port = port);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _eventSubscription?.cancel();
    _receiver.dispose();
    _deviceService.stopAdvertising();
    _deviceService.dispose();
    super.dispose();
  }

  void _showNearbyEvent(NearbyEventAnnouncement event) {
    if (!mounted || !_seenEventIds.add(event.eventId)) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nearby Event', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: AppSpacing.xs),
            Text('${event.device.name} created ${event.eventName}', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            Text('Contribute your photos?', style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Not Now'))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: FilledButton(onPressed: () { Navigator.pop(sheetContext); context.push(AppRoutes.eventContribution, extra: event.device); }, child: const Text('Join'))),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Receive Files', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
              ),
              child: const Icon(Icons.download_for_offline_outlined, size: 40, color: AppColors.secondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _error != null
                ? 'Receive unavailable'
                : progress?.isComplete == true
                  ? 'Transfer complete'
                  : progress == null
                    ? 'Ready to receive'
                    : 'Receiving files',
              style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (progress == null)
              Text(
                _port == null && _error == null
                  ? 'Starting secure local receiver...'
                  : _error == null
                      ? 'Listening on port $_port'
                      : 'Another app may already be using the transfer port.',
                style: AppTypography.labelLg.copyWith(color: AppColors.secondaryContainer),
              )
            else ...[
              Text(
                progress.isComplete
                    ? 'File verified'
                    : '${progress.percent}% receiving',
                style: AppTypography.labelLg.copyWith(color: AppColors.secondaryContainer),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 280,
                child: LinearProgressIndicator(
                  value: progress.fraction.clamp(0, 1),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(AppSpacing.full),
                  color: AppColors.secondary,
                  backgroundColor: AppColors.surfaceContainerHigh,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                progress.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
              ),
              Text(
                '${FileSizeFormatter.format(progress.totalBytesTransferred)} / ${FileSizeFormatter.format(progress.totalBytes)} · ${FileSizeFormatter.formatSpeed(progress.speedBytesPerSecond)}',
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
            if (progress == null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Incoming transfers will be written to this device after a session is established.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (_receivedPaths.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Received files',
                style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final path in _receivedPaths)
                ListTile(
                  leading: const Icon(Icons.insert_drive_file, color: AppColors.secondary),
                  title: Text(
                    path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
                  ),
                  trailing: IconButton(
                    tooltip: 'Open file',
                    icon: const Icon(Icons.open_in_new, color: AppColors.secondary),
                    onPressed: () => _openFile(path),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openFile(String path) async {
    try {
      await const MethodChannel('flowsend/device').invokeMethod<void>(
        'openFile',
        {'path': path},
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app can open this file type.')),
        );
      }
    }
  }
}
