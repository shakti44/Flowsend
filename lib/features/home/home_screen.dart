import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/transfer_record.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../core/utils/time_formatter.dart';
import '../../services/history_service.dart';
import '../../widgets/flowsend_logo.dart';
import '../../widgets/primary_pill_button.dart';
import '../../widgets/device_chip.dart';
import '../../routes/app_router.dart';

/// FlowSend Home Screen — matches the Stitch flowsend_home design exactly.
/// Features: radar orb, Send Files CTA, Receive + My Devices grid,
/// Zero-Knowledge security pill, Recent Transfers list, bottom nav.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pingController;
  late final Animation<double> _pingAnim;
  List<TransferRecord> _recentTransfers = const [];

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pingController, curve: Curves.easeOut),
    );
    _loadRecentTransfers();
  }

  Future<void> _loadRecentTransfers() async {
    final records = await HistoryService().load();
    if (mounted) setState(() => _recentTransfers = records.take(2).toList());
  }

  @override
  void dispose() {
    _pingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Keep the atmosphere quiet so the send action stays dominant.
          const _AmbientGlows(),

          CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader(context)),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero canvas
                    _buildHeroSection(context),
                    const SizedBox(height: AppSpacing.md),

                    // Security verification pill
                    _buildSecurityPill(),
                    const SizedBox(height: AppSpacing.lg),

                    // Recent transfers
                    _buildRecentTransfers(context),
                    const SizedBox(height: 120), // bottom nav clearance
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPad,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      height: 72 + topPad,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.80),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const FlowSendLogo(size: 30),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FlowSend',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              Text(
                'HOME',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.tune, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
            ),
            child: const Icon(Icons.person, color: AppColors.secondary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),

        // Tagline badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulsingDot(color: AppColors.secondaryContainer),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'MOVE ANYTHING. ANYWHERE.',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Radar orb
        _buildRadarOrb(),

        const SizedBox(height: AppSpacing.md),

        // Headline
        Text(
          'Send with confidence.',
          style: AppTypography.headlineXlMobile.copyWith(
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          'Move files directly to a nearby device,\nwithout the clutter.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.md),

        // Primary CTA: + Send Files
        PrimaryPillButton(
          label: '+ Send Files',
          icon: Icons.add_circle_outline,
          onPressed: () => context.push(AppRoutes.selectFiles),
          height: 58,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Secondary actions grid
        Row(
          children: [
            Expanded(
              child: SecondaryPillButton(
                label: 'Receive',
                icon: Icons.download_for_offline_outlined,
                iconColor: AppColors.secondaryFixedDim,
                onPressed: () => context.push(AppRoutes.receive),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SecondaryPillButton(
                label: 'My Devices',
                icon: Icons.devices,
                iconColor: AppColors.primary,
                onPressed: () => context.push(AppRoutes.devices),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadarOrb() {
    final size = MediaQuery.sizeOf(context).width < 380 ? 144.0 : 156.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ping ring
          AnimatedBuilder(
            animation: _pingAnim,
            builder: (_, __) {
              return Opacity(
                opacity: (1 - _pingAnim.value) * 0.25,
                child: Transform.scale(
                  scale: 0.7 + _pingAnim.value * 0.3,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              );
            },
          ),

          // Mid ring
          Container(
            width: size - 16,
            height: size - 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.40),
            ),
          ),

          // Inner ring
          Container(
            width: size - 38,
            height: size - 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainer.withValues(alpha: 0.60),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 12),
              ],
            ),
          ),

          // Logo orb at center
          FlowSendLogoOrb(size: size * 0.54),

          // Orbital pips
          const Positioned(
            top: 6,
            right: 18,
            child: _GlowPip(color: AppColors.secondaryContainer, size: 12),
          ),
          const Positioned(
            bottom: 12,
            left: 18,
            child: _GlowPip(color: AppColors.primary, size: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPill() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainer,
            ),
            child: const Icon(Icons.verified_user, color: AppColors.secondary, size: 16),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protected transfer',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'SHA-256 verification enabled',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SecurityPill(isActive: true),
        ],
      ),
    );
  }

  Widget _buildRecentTransfers(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Recent Transfers',
              style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainer,
              ),
              child: Center(
                child: Text(
                  '${_recentTransfers.length}',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push(AppRoutes.history),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'View all',
                style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...(_recentTransfers.map((record) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _RecentTransferCard(
                item: _RecentTransferItem.fromRecord(record),
              ),
            ))),
        if (_recentTransfers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'No transfers yet',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -40,
          left: MediaQuery.of(context).size.width / 2 - 96,
          child: Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          top: 228,
          left: MediaQuery.of(context).size.width / 3 - 64,
          child: Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryContainer.withValues(alpha: 0.08),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _a.value),
        ),
      ),
    );
  }
}

class _GlowPip extends StatelessWidget {
  const _GlowPip({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.8),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _RecentTransferItem {
  const _RecentTransferItem({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.size,
    required this.device,
    required this.timeAgo,
    required this.isSuccess,
  });
  final IconData icon;
  final Color iconColor;
  final String name;
  final String size;
  final String device;
  final String timeAgo;
  final bool isSuccess;

  factory _RecentTransferItem.fromRecord(TransferRecord record) {
    return _RecentTransferItem(
      icon: record.fileCount > 1
          ? Icons.folder_zip_outlined
          : Icons.insert_drive_file_outlined,
      iconColor: record.isSuccess ? AppColors.secondaryFixedDim : AppColors.error,
      name: record.fileName,
      size: FileSizeFormatter.format(record.totalSizeBytes),
      device: record.peerDevice.name,
      timeAgo: TimeFormatter.formatRelative(record.completedAt),
      isSuccess: record.isSuccess,
    );
  }
}

class _RecentTransferCard extends StatelessWidget {
  const _RecentTransferCard({required this.item});
  final _RecentTransferItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.labelLg.copyWith(color: AppColors.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.size,
                      style: AppTypography.telemetryData.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('·',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          )),
                    ),
                    Flexible(
                      child: Text(
                        item.device,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('·',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          )),
                    ),
                    Text(
                      item.timeAgo,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              item.isSuccess ? Icons.check : Icons.error_outline,
              size: 16,
              color: item.isSuccess ? AppColors.secondary : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
