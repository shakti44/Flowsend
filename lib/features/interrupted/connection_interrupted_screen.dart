import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/transfer_session.dart';

/// Connection Interrupted Screen — matches Stitch connection_interrupted design.
/// Shows auto-reconnect animation, resilient hash ledger info, countdown.
class ConnectionInterruptedScreen extends StatefulWidget {
  const ConnectionInterruptedScreen({super.key, required this.session});
  final TransferSession session;

  @override
  State<ConnectionInterruptedScreen> createState() =>
      _ConnectionInterruptedScreenState();
}

class _ConnectionInterruptedScreenState
    extends State<ConnectionInterruptedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pingController;
  int _countdown = 3;
  Timer? _countdownTimer;
  bool _isResuming = false;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          t.cancel();
          _attemptResume();
        }
      });
    });
  }

  void _attemptResume() {
    setState(() => _isResuming = true);
    // In production: TransferService.resume() is called here.
    // For now: simulate going back to active transfer after 1s.
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.pop();
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pingController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = widget.session.overallPercent;
    final transferred = FileSizeFormatter.format(widget.session.overallTransferredBytes);
    final total = FileSizeFormatter.format(widget.session.totalBytes);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // Status bar: auto-reconnecting
              _buildStatusBar(),
              const SizedBox(height: AppSpacing.md),

              // Centerpiece: reconnect animation
              _buildReconnectCard(percent, transferred, total),
              const SizedBox(height: AppSpacing.md),

              // Auto-recovery telemetry
              _buildRecoveryCard(),
              const SizedBox(height: AppSpacing.md),

              // Active file card
              _buildActiveFileCard(),
              const SizedBox(height: AppSpacing.md),

              // Actions
              _buildActions(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
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
        onPressed: () => context.pop(),
      ),
      title: Text('Transfer Session',
          style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 14, height: 14,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pingController,
                      builder: (_, __) => Transform.scale(
                        scale: 1 + _pingController.value * 0.5,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary.withValues(alpha: (1 - _pingController.value) * 0.75),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 8, height: 8,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.secondaryContainer)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('AUTO-RECONNECTING',
                  style: AppTypography.labelSm.copyWith(color: AppColors.secondary, letterSpacing: 1.2)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppSpacing.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_protected_setup, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text('P2P v2.4', style: AppTypography.telemetryData.copyWith(color: AppColors.onSurface)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sending to ${widget.session.targetDevice.name}',
                      style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
                  Text(widget.session.targetDevice.protocolInfo ?? 'Searching...',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerLowest,
                ),
                child: const Icon(Icons.laptop_mac, size: 20, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReconnectCard(int percent, String transferred, String total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20)],
      ),
      child: Column(
        children: [
          // Reconnecting spinner
          SizedBox(
            width: 112, height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pingController,
                  builder: (_, __) => Container(
                    width: 112, height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondaryContainer.withValues(
                          alpha: (1 - _pingController.value) * 0.1),
                    ),
                  ),
                ),
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  ),
                ),
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerLowest,
                  ),
                  child: RotationTransition(
                    turns: _spinController,
                    child: const Icon(Icons.sync, size: 32, color: AppColors.secondary),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 8,
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerHighest,
                    ),
                    child: const Icon(Icons.lock, size: 15, color: AppColors.primaryFixedDim),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Connection interrupted',
              style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface)),
          Text("Don't worry — your transfer is safe.",
              style: AppTypography.bodyMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Payload locked at exact cryptographic state. No duplicate packets required.',
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // State pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary)),
                const SizedBox(width: 6),
                Text('$percent% Complete', style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
                Text(' · ', style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
                Text('$transferred / $total',
                    style: AppTypography.telemetryData.copyWith(color: AppColors.secondaryFixed)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.full),
            child: LinearProgressIndicator(
              value: widget.session.overallFraction,
              backgroundColor: AppColors.surfaceContainerLowest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryContainer),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Block ${(widget.session.overallTransferredBytes / (64 * 1024)).round()} verified',
                  style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              Text('SHA-256 Verified',
                  style: AppTypography.telemetryData.copyWith(color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AUTO-RECOVERY TELEMETRY',
                  style: AppTypography.labelSm.copyWith(color: AppColors.outline, letterSpacing: 1.2)),
              Text('Attempt 1 of 5',
                  style: AppTypography.telemetryData.copyWith(color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _RecoveryStep(
            icon: Icons.sensors,
            iconColor: AppColors.secondary,
            title: 'Probing Direct Wi-Fi Channel',
            subtitle: 'Switching to Bluetooth LE handshake + Wi-Fi Direct re-negotiation',
            status: 'Active',
            statusColor: AppColors.secondary,
            isActive: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          _RecoveryStep(
            icon: Icons.verified_user,
            iconColor: AppColors.tertiaryFixedDim,
            title: 'Resilient Hash Ledger',
            subtitle: 'FlowSend uses chunked cryptographic hashing. No restart needed.',
            status: '',
            statusColor: AppColors.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFileCard() {
    final file = widget.session.currentFile;
    if (file == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: const Icon(Icons.video_file, size: 24, color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
                    overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Text('Paused at block #${(widget.session.sessionCheckpoint ?? 0) ~/ (64 * 1024)}',
                        style: AppTypography.labelSm.copyWith(color: AppColors.secondaryFixedDim)),
                    Text(' • ', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                    Text(
                      FileSizeFormatter.format(
                          file.sizeBytes - (widget.session.sessionCheckpoint ?? 0)),
                      style: AppTypography.telemetryData.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    Text(' remaining',
                        style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
            ),
            child: const Icon(Icons.pause, size: 18, color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _isResuming ? null : _attemptResume,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isResuming
                    ? 'Resuming from ${widget.session.overallPercent}%...'
                    : _countdown > 0
                        ? 'Auto-resuming in ${_countdown}s...'
                        : 'Resume',
                key: ValueKey('$_isResuming$_countdown'),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              foregroundColor: AppColors.onSurface,
            ),
            icon: const Icon(Icons.close, size: 18, color: AppColors.outline),
            label: const Text('Cancel Transfer'),
          ),
        ),
      ],
    );
  }
}

class _RecoveryStep extends StatelessWidget {
  const _RecoveryStep({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.isActive = false,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: isActive ? 0.6 : 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.xs + 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
                    ),
                    if (status.isNotEmpty)
                      Text(status, style: AppTypography.bodySm.copyWith(color: statusColor)),
                  ],
                ),
                Text(subtitle, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
