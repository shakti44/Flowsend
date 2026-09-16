import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/discovered_device.dart';
import '../../models/selected_file.dart';
import '../../services/transfer_service/multi_device_transfer_manager.dart';
import '../../widgets/device_chip.dart';
import '../../routes/app_router.dart';

class MultiDeviceTransferScreen extends StatefulWidget {
  const MultiDeviceTransferScreen({
    super.key,
    required this.files,
    required this.devices,
    this.filesByDevice,
  });

  final List<SelectedFile> files;
  final List<DiscoveredDevice> devices;
  final Map<String, List<SelectedFile>>? filesByDevice;

  @override
  State<MultiDeviceTransferScreen> createState() => _MultiDeviceTransferScreenState();
}

class _MultiDeviceTransferScreenState extends State<MultiDeviceTransferScreen> {
  late final MultiDeviceTransferManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = MultiDeviceTransferManager();
    _manager.configure(
      selectedFiles: widget.files,
      devices: widget.devices,
      selectedFilesByDevice: widget.filesByDevice,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _manager.start());
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    await _manager.cancelAll();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _manager,
      builder: (context, _) {
        final complete = _manager.isComplete;
        final partial = _manager.isPartiallyComplete && !complete;
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.onSurface),
              onPressed: complete || partial ? () => context.go(AppRoutes.home) : _cancel,
            ),
            title: Text(
              complete ? 'Transfer complete' : partial ? 'Partially complete' : 'Multi-Device Transfer',
              style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _buildSummary(complete, partial),
                const SizedBox(height: AppSpacing.lg),
                ..._manager.items.map(_buildDeviceCard),
                if (partial) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => _manager.retryFailed(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Failed'),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (complete || partial)
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text('Done'),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _cancel,
                    child: Text('Cancel all transfers', style: TextStyle(color: AppColors.error)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(bool complete, bool partial) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.devices.length} devices · ${widget.files.length} files · ${FileSizeFormatter.format(_manager.totalBytes)}',
            style: AppTypography.labelLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.full),
                  child: LinearProgressIndicator(
                    value: _manager.overallFraction.clamp(0, 1),
                    minHeight: 10,
                    color: complete ? AppColors.securityGreen : AppColors.secondary,
                    backgroundColor: AppColors.surfaceContainerHigh,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${_manager.overallPercent}%', style: AppTypography.telemetryData.copyWith(color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            complete ? 'Every receiver verified the transfer.' : partial ? 'Some receivers need attention.' : 'Transfers run independently. One failure will not stop the others.',
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(MultiDeviceTransferItem item) {
    final isDone = item.state == MultiDeviceItemState.completed;
    final isFailed = item.state == MultiDeviceItemState.failed;
    final stateText = switch (item.state) {
      MultiDeviceItemState.queued => 'Queued',
      MultiDeviceItemState.connecting => 'Connecting...',
      MultiDeviceItemState.transferring => '${item.percent}% · ${FileSizeFormatter.formatSpeed(item.speedBytesPerSecond)}',
      MultiDeviceItemState.paused => 'Paused',
      MultiDeviceItemState.interrupted => 'Reconnecting...',
      MultiDeviceItemState.completed => 'Completed · Verified',
      MultiDeviceItemState.failed => 'Failed',
      MultiDeviceItemState.cancelled => 'Cancelled',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFailed ? AppColors.error.withValues(alpha: 0.65) : AppColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              DevicePlatformIcon(platform: item.device.platform, size: 28, color: isDone ? AppColors.securityGreen : AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(item.device.name, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
              ),
              Icon(
                isDone ? Icons.check_circle : isFailed ? Icons.error : Icons.sync,
                color: isDone ? AppColors.securityGreen : isFailed ? AppColors.error : AppColors.secondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(stateText, style: AppTypography.bodySm.copyWith(color: isFailed ? AppColors.error : AppColors.onSurfaceVariant)),
          ),
          if (item.state == MultiDeviceItemState.transferring || isDone) ...[
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: item.percent / 100,
              minHeight: 6,
              borderRadius: BorderRadius.circular(AppSpacing.full),
              color: isDone ? AppColors.securityGreen : AppColors.secondary,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${FileSizeFormatter.format(item.transferredBytes)} / ${FileSizeFormatter.format(_manager.bytesFor(item.device.id))}',
                style: AppTypography.telemetryData.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
          if (isFailed) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _manager.retry(item.device.id),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Retry ${item.device.name}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
