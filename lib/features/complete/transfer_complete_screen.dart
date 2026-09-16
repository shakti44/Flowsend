import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../core/utils/time_formatter.dart';
import '../../models/transfer_session.dart';
import '../../models/transfer_record.dart';
import '../../services/history_service.dart';
import '../../widgets/device_chip.dart';
import '../../routes/app_router.dart';

/// Transfer Complete Screen — matches Stitch transfer_complete design.
/// Animated checkmark, file preview grid, summary card, action buttons.
class TransferCompleteScreen extends StatefulWidget {
  const TransferCompleteScreen({super.key, required this.session});
  final TransferSession session;

  @override
  State<TransferCompleteScreen> createState() => _TransferCompleteScreenState();
}

class _TransferCompleteScreenState extends State<TransferCompleteScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _glowController;
  late final Animation<double> _checkAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _saveHistory();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _checkAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeOut),
    );
    _glowAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _saveHistory() async {
    final session = widget.session;
    await HistoryService().add(
      TransferRecord(
        id: session.id,
        sessionId: session.id,
        fileName: session.files.length == 1
            ? session.files.first.name
            : '${session.files.length} files',
        fileCount: session.files.length,
        totalSizeBytes: session.totalBytes,
        direction: TransferDirection.sent,
        peerDevice: session.targetDevice,
        startedAt: session.startedAt,
        completedAt: session.completedAt ?? DateTime.now(),
        state: TransferRecordState.completed,
        averageSpeedBytesPerSecond: session.speedBytesPerSecond,
        integrityVerified: session.fileIntegrityResults.length == session.files.length &&
            session.fileIntegrityResults.values.every((verified) => verified),
      ),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final duration = session.elapsed;
    final avgSpeed = session.elapsed.inSeconds > 0
        ? (session.totalBytes / session.elapsed.inSeconds)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // Status chip
              _buildStatusChip(context),
              const SizedBox(height: AppSpacing.md),

              // Animated success hero
              _buildSuccessHero(),
              const SizedBox(height: AppSpacing.lg),

              // Title + subtitle
              Text('Transfer complete',
                  style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'All files successfully delivered & verified',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // File preview grid
              _buildFilePreviewGrid(session),
              const SizedBox(height: AppSpacing.md),

              // Summary card
              _buildSummaryCard(session, duration, avgSpeed),
              const SizedBox(height: AppSpacing.lg),

              // Action buttons
              _buildActions(context),
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
        onPressed: () => context.go(AppRoutes.home),
      ),
      title: Text('Transfer Session',
          style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
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
              Text('P2P Channel Closed', style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go(AppRoutes.home),
          icon: const Icon(Icons.close, size: 20, color: AppColors.onSurfaceVariant),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceContainerHigh,
            shape: const CircleBorder(),
            fixedSize: const Size(36, 36),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessHero() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ambient glow
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            width: 176,
            height: 176,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.20 * _glowAnim.value),
                  AppColors.secondaryContainer.withValues(alpha: 0.25 * _glowAnim.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Background circle
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHigh,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryContainer.withValues(alpha: 0.45),
                blurRadius: 40,
                spreadRadius: -8,
              ),
            ],
          ),
        ),

        // Gradient inner circle
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary,
                AppColors.secondaryContainer,
                AppColors.primary,
              ],
            ),
          ),
        ),

        // Animated check
        AnimatedBuilder(
          animation: _checkAnim,
          builder: (_, __) => CustomPaint(
            size: const Size(80, 80),
            painter: _CheckmarkPainter(progress: _checkAnim.value),
          ),
        ),

        // "100% OK" pill
        Positioned(
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.securityGreen.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppSpacing.full),
              border: Border.all(color: AppColors.securityGreen.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.securityGreen)),
                const SizedBox(width: 4),
                Text('100% OK', style: AppTypography.labelSm.copyWith(color: AppColors.securityGreen)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreviewGrid(TransferSession session) {
    final files = session.files.take(3).toList();
    if (files.isEmpty) return const SizedBox.shrink();

    return Row(
      children: files.asMap().entries.map((entry) {
        final i = entry.key;
        final file = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < files.length - 1 ? AppSpacing.xs : 0),
            child: _FilePreviewCard(file: file),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(TransferSession session, Duration duration, double avgSpeed) {
    final allVerified = session.fileIntegrityResults.values.every((v) => v);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
      ),
      child: Column(
        children: [
          // Device header
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainer,
                ),
                child: DevicePlatformIcon(platform: session.targetDevice.platform, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.targetDevice.name,
                      style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
                  Text(session.targetDevice.protocolInfo ?? 'P2P Transfer',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              Icon(Icons.check_circle, color: AppColors.secondary, size: 24),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.outlineVariant, height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Summary rows
          _SummaryRow(
            label: 'Payload',
            value: '${session.files.length} item${session.files.length == 1 ? '' : 's'}',
            valueColor: AppColors.onSurface,
          ),
          _SummaryRow(
            label: 'Total Size',
            value: FileSizeFormatter.format(session.totalBytes),
            valueColor: AppColors.onSurface,
          ),
          _SummaryRow(
            label: 'Duration',
            value: TimeFormatter.formatDuration(duration),
            valueColor: AppColors.onSurface,
            badge: '${FileSizeFormatter.formatSpeed(avgSpeed.round())} avg',
          ),
          _SummaryRow(
            label: 'Integrity',
            value: allVerified ? 'SHA-256 Valid' : 'Verifying...',
            valueColor: allVerified ? AppColors.secondary : AppColors.outline,
            badgeColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Open Files
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.folder_open, size: 20),
            label: Text('Open Files', style: AppTypography.labelLg.copyWith(color: AppColors.onPrimaryContainer)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Send More
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              foregroundColor: AppColors.onSurface,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Send More'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // View Details
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
          child: Text('View Details & Audit Log',
              style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
        ),
      ],
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final check = Path()
      ..moveTo(cx - 18, cy)
      ..lineTo(cx - 6, cy + 12)
      ..lineTo(cx + 16, cy - 14);

    final paint = Paint()
      ..color = AppColors.onPrimaryContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final metrics = check.computeMetrics().toList();
    for (final metric in metrics) {
      final drawn = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(drawn, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) => old.progress != progress;
}

class _FilePreviewCard extends StatelessWidget {
  const _FilePreviewCard({required this.file});
  final dynamic file;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.base),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          const Center(child: Icon(Icons.insert_drive_file_outlined, size: 28, color: AppColors.secondary)),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.surfaceContainerLowest],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              file.name as String,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.badge,
    this.badgeColor,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
          ),
          const Spacer(),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.secondary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.full),
              ),
              child: Text(badge!,
                  style: AppTypography.telemetryData.copyWith(
                      color: badgeColor ?? AppColors.secondary, fontSize: 10)),
            ),
            const SizedBox(width: 8),
          ],
          Text(value,
              style: AppTypography.labelMd.copyWith(
                  color: valueColor ?? AppColors.onSurface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
