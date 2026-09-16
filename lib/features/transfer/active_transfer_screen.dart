import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../core/utils/time_formatter.dart';
import '../../models/discovered_device.dart';
import '../../models/selected_file.dart';
import '../../models/transfer_session.dart';
import '../../services/transfer_service/transfer_service.dart';
import '../../widgets/transfer_ring.dart';
import '../../widgets/device_chip.dart';
import '../../routes/app_router.dart';

/// Active Transfer Screen — matches Stitch active_transfer design.
/// Circular progress ring, speed/ETA telemetry, Pause/Cancel controls.
class ActiveTransferScreen extends StatefulWidget {
  const ActiveTransferScreen({
    super.key,
    required this.files,
    required this.device,
  });

  final List<SelectedFile> files;
  final DiscoveredDevice device;

  @override
  State<ActiveTransferScreen> createState() => _ActiveTransferScreenState();
}

class _ActiveTransferScreenState extends State<ActiveTransferScreen> {
  late final TransferService _transferService;

  @override
  void initState() {
    super.initState();
    _transferService = TransferService();
    // Start transfer after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transferService.startTransfer(
        files: widget.files,
        targetDevice: widget.device,
      );
    });
  }

  @override
  void dispose() {
    _transferService.dispose();
    super.dispose();
  }

  void _togglePause() {
    final session = _transferService.activeSession;
    if (session == null) return;
    if (session.state == TransferState.paused) {
      _transferService.resume();
    } else {
      _transferService.pause();
    }
  }

  Future<void> _cancelTransfer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Cancel transfer?', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
        content: Text(
          'Your original files are safe. The partial transfer on the other device will be discarded.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel transfer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _transferService.cancel();
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _transferService,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: _buildAppBar(context),
        body: Consumer<TransferService>(
          builder: (context, service, _) {
            final session = service.activeSession;

            // Navigate to complete or interrupted screens
            if (session != null) {
              if (session.state == TransferState.completed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.pushReplacement(AppRoutes.transferComplete, extra: session);
                  }
                });
              }
              if (session.state == TransferState.interrupted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.push(AppRoutes.connectionInterrupted, extra: session);
                  }
                });
              }
            }

            return _buildBody(session);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.onSurface),
        onPressed: _cancelTransfer,
      ),
      title: Text('Transfer Session',
          style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      actions: [
        Container(
          width: 32, height: 32,
          margin: const EdgeInsets.only(right: AppSpacing.md),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
          child: const Icon(Icons.person, size: 18, color: AppColors.onPrimary),
        ),
      ],
    );
  }

  Widget _buildBody(TransferSession? session) {
    final isPaused = session?.state == TransferState.paused;
    final progress = session?.overallFraction ?? 0.0;
    final percent = session?.overallPercent ?? 0;
    final speed = session?.speedBytesPerSecond ?? 0;
    final etaSec = session?.etaSeconds ?? 0;
    final currentFile = session?.currentFile;
    final fileProgress = session != null &&
            session.currentFileIndex < session.fileProgress.length
        ? session.fileProgress[session.currentFileIndex]
        : null;

    return Stack(
      children: [
        // Background glows
        Positioned(
          top: 48, left: 0, right: 0,
          child: Center(
            child: Container(
              width: 256, height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.20),
              ),
            ),
          ),
        ),
        Positioned(
          top: 112, left: 0, right: 0,
          child: Center(
            child: Container(
              width: 192, height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryContainer.withValues(alpha: 0.25),
              ),
            ),
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Header: speed badge + destination
                _buildTransferHeader(speed),

                // Main: circular progress ring
                const SizedBox(height: AppSpacing.sm),
                TransferRing(
                  progress: progress,
                  size: 256,
                  centerChild: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$percent',
                              style: AppTypography.headlineXl.copyWith(
                                color: AppColors.onSurface,
                                shadows: [
                                  Shadow(
                                    color: AppColors.secondaryContainer.withValues(alpha: 0.45),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: '%',
                              style: AppTypography.headlineMd.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.schedule, size: 15, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            TimeFormatter.formatEta(etaSec),
                            style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Packet stream device indicator
                const SizedBox(height: AppSpacing.sm),
                _buildPacketStream(),

                // File details card
                const SizedBox(height: AppSpacing.md),
                _buildFileCard(currentFile, fileProgress, session),

                // Security banner
                const SizedBox(height: AppSpacing.sm),
                _buildSecurityBanner(),

                // Controls
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildControlButton(
                        icon: isPaused ? Icons.play_arrow : Icons.pause,
                        label: isPaused ? 'Resume' : 'Pause',
                        isActive: isPaused,
                        onTap: _togglePause,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildControlButton(
                        icon: Icons.close,
                        label: 'Cancel',
                        isError: true,
                        onTap: _cancelTransfer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransferHeader(int speedBps) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppSpacing.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryContainer,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '⚡ ${FileSizeFormatter.formatSpeed(speedBps)}',
                style: AppTypography.telemetryData.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sending to ${widget.device.name}',
          style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Wi-Fi 6 Direct', style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
            Container(
              width: 4, height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.outlineVariant),
            ),
            Text('End-to-End Encrypted', style: AppTypography.labelSm.copyWith(color: AppColors.tertiary)),
          ],
        ),
      ],
    );
  }

  Widget _buildPacketStream() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSpacing.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DevicePlatformIcon(platform: DevicePlatform.ios, size: 20, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('iPhone', style: AppTypography.labelSm.copyWith(color: AppColors.onSurface)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _FlowDot(color: AppColors.secondaryContainer, delay: 0),
                  _FlowDot(color: AppColors.primary, delay: 75),
                  _FlowDot(color: AppColors.secondaryContainer, delay: 150),
                ],
              ),
            ),
          ),
          Text(widget.device.name.split(' ').first,
              style: AppTypography.labelSm.copyWith(color: AppColors.onSurface)),
          const SizedBox(width: 6),
          DevicePlatformIcon(platform: widget.device.platform, size: 20, color: AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildFileCard(SelectedFile? file, FileTransferProgress? fp, TransferSession? session) {
    if (file == null) return const SizedBox.shrink();
    final fileBytes = fp?.transferredBytes ?? 0;
    final fileTotal = file.sizeBytes;
    final fileProgress = fp?.fraction ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: const Icon(Icons.movie, size: 26, color: AppColors.primaryFixedDim),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name,
                        style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${FileSizeFormatter.format(fileBytes)} / ${FileSizeFormatter.format(fileTotal)}',
                          style: AppTypography.telemetryData.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        Text(
                          'File ${(session?.currentFileIndex ?? 0) + 1} of ${session?.files.length ?? 1}',
                          style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Per-file progress bar
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.full),
            child: LinearProgressIndicator(
              value: fileProgress,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryContainer),
              minHeight: 8,
            ),
          ),

          // Telemetry grid
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppSpacing.xs + 2),
            ),
            child: Row(
              children: [
                _buildTelemetryCell('Speed', FileSizeFormatter.formatSpeed(session?.speedBytesPerSecond ?? 0), AppColors.secondary),
                _buildTelemetryCell('Time Left', TimeFormatter.formatClock(Duration(seconds: session?.etaSeconds ?? 0)), AppColors.onSurface),
                _buildTelemetryCell('Link', '5GHz Direct', AppColors.tertiary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.playlist_play, size: 16, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${session?.files.length ?? 0} files total (${FileSizeFormatter.format(session?.totalBytes ?? 0)} aggregate)',
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.wifi, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text('100% Signal', style: AppTypography.labelSm.copyWith(color: AppColors.secondaryFixed)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCell(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.telemetryData.copyWith(color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSpacing.full),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryContainer,
              boxShadow: [BoxShadow(color: AppColors.secondaryContainer.withValues(alpha: 0.7), blurRadius: 10)],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('TLS 1.3 · ChaCha20 Poly1305',
                style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          ),
          const Icon(Icons.verified_user, size: 16, color: AppColors.tertiary),
          const SizedBox(width: 4),
          Text('Secured', style: AppTypography.labelSm.copyWith(color: AppColors.tertiary)),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    bool isError = false,
    required VoidCallback onTap,
  }) {
    Color bg;
    Color fg;
    if (isError) {
      bg = AppColors.errorContainer.withValues(alpha: 0.4);
      fg = AppColors.onErrorContainer;
    } else if (isActive) {
      bg = AppColors.primaryContainer;
      fg = AppColors.onPrimaryContainer;
    } else {
      bg = AppColors.surfaceContainerHigh.withValues(alpha: 0.8);
      fg = AppColors.onSurface;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.full),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.labelLg.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _FlowDot extends StatefulWidget {
  const _FlowDot({required this.color, required this.delay});
  final Color color;
  final int delay;

  @override
  State<_FlowDot> createState() => _FlowDotState();
}

class _FlowDotState extends State<_FlowDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: 1200 + widget.delay))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 8, height: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.full),
          color: widget.color.withValues(alpha: 0.5 + _c.value * 0.5),
          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.8), blurRadius: 8)],
        ),
      ),
    );
  }
}
