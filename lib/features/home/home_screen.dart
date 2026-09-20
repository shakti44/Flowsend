import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../core/utils/time_formatter.dart';
import '../../models/discovered_device.dart';
import '../../models/transfer_record.dart';
import '../../services/device_service/lan_device_service.dart';
import '../../services/history_service.dart';
import '../../widgets/device_chip.dart';
import '../../widgets/flowsend_logo.dart';
import '../../widgets/primary_pill_button.dart';
import '../../routes/app_router.dart';
import 'flow_assistant_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _deviceService = LanDeviceService();
  List<DiscoveredDevice> _devices = const [];
  List<TransferRecord> _recentTransfers = const [];
  final _seenEventIds = <String>{};
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _deviceService.devicesStream.listen((devices) {
      if (mounted) setState(() => _devices = devices);
    });
    _deviceService.eventStream.listen(_showNearbyEvent);
    _deviceService.startDiscovery();
    _loadRecentTransfers();
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

  Future<void> _loadRecentTransfers() async {
    final records = await HistoryService().load();
    if (mounted) setState(() => _recentTransfers = records.take(2).toList());
  }

  @override
  void dispose() {
    _deviceService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _openAssistant() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      builder: (_) => const FlowAssistantSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHero(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildNearbyDevices(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTrustLine(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRecentTransfers(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          const FlowSendLogo(size: 30),
          const SizedBox(width: AppSpacing.sm),
          Text('FlowSend', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            tooltip: 'Flow Assistant',
            onPressed: _openAssistant,
            icon: const Icon(Icons.mic_none, size: 21),
            style: IconButton.styleFrom(foregroundColor: AppColors.secondary, backgroundColor: AppColors.surfaceContainerLow, shape: const CircleBorder(), elevation: 4, shadowColor: AppColors.secondary.withValues(alpha: 0.25)),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Profile',
            onPressed: () {},
            icon: const Icon(Icons.person_outline, size: 21),
            style: IconButton.styleFrom(foregroundColor: AppColors.onSurfaceVariant, backgroundColor: AppColors.surfaceContainerLow, shape: const CircleBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text('Share anything', style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xs),
        Text('Photos  •  Videos  •  Apps  •  Files', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.lg),
        _buildOrb(),
        const SizedBox(height: AppSpacing.lg),
        PrimaryPillButton(label: 'Send Files', icon: Icons.arrow_upward_rounded, onPressed: () => context.push(AppRoutes.selectFiles), height: 56),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _QuickAction(icon: Icons.download_outlined, label: 'Receive', onTap: () => context.push(AppRoutes.receive))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _QuickAction(icon: Icons.collections_outlined, label: 'Event Rescue', onTap: () => context.push(AppRoutes.eventRescue))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _QuickAction(icon: Icons.phone_android_outlined, label: 'New Phone', onTap: () => context.push(AppRoutes.newPhone))),
          ],
        ),
      ],
    );
  }

  Widget _buildOrb() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => SizedBox(
        width: 154,
        height: 154,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_devices.isEmpty) ...[
              _RadarRing(progress: _pulseController.value, size: 154),
              _RadarRing(progress: (_pulseController.value + 0.5) % 1, size: 132),
            ],
            Container(width: 154, height: 154, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.secondary.withValues(alpha: 0.14 + _pulseController.value * 0.14), width: 1))),
            Container(width: 126, height: 126, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerLow, border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.55)), boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.13), blurRadius: 28, spreadRadius: 2)])),
            const FlowSendLogoOrb(size: 82),
            Positioned(top: 3, right: 28, child: Container(width: 9, height: 9, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.secondaryContainer))),
            Positioned(bottom: 12, left: 25, child: Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary))),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyDevices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Text('Nearby Devices', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)), const Spacer(), TextButton(onPressed: () => context.push(AppRoutes.devices), child: const Text('See all'))]),
        const SizedBox(height: AppSpacing.sm),
        if (_devices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.radar, color: AppColors.secondary, size: 24), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('No nearby devices\nOpen FlowSend on another device to discover it.', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant))), IconButton(onPressed: () => _deviceService.startDiscovery(), icon: const Icon(Icons.refresh, color: AppColors.secondary))]),
          )
        else
          SizedBox(height: 100, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _devices.length, separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm), itemBuilder: (context, index) => _DevicePreview(device: _devices[index]))),
      ],
    );
  }

  Widget _buildTrustLine() {
    return Row(children: [const Icon(Icons.shield_outlined, size: 18, color: AppColors.secondary), const SizedBox(width: AppSpacing.sm), Text('Direct & protected', style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant)), const Spacer(), Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.securityGreen)), const SizedBox(width: 5), Text('Active', style: AppTypography.labelSm.copyWith(color: AppColors.securityGreen))]);
  }

  Widget _buildRecentTransfers() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('Recent', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)), const Spacer(), TextButton(onPressed: () => context.push(AppRoutes.history), child: const Text('See all'))]),
      const SizedBox(height: AppSpacing.sm),
      if (_recentTransfers.isEmpty) Text('No transfers yet', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)) else ..._recentTransfers.asMap().entries.map((entry) => _RecentTransferRow(record: entry.value, delay: entry.key * 90)),
    ]);
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Column(children: [Container(width: 42, height: 42, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerHigh), child: Icon(icon, color: AppColors.secondary, size: 21)), const SizedBox(height: 6), Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant))])));
}

class _DevicePreview extends StatelessWidget {
  const _DevicePreview({required this.device});
  final DiscoveredDevice device;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
        key: ValueKey(device.id),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(12 * (1 - value), 0),
            child: child,
          ),
        ),
        child: Container(
          width: 116,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DevicePlatformIcon(platform: device.platform, size: 22, color: AppColors.secondary),
                  const Spacer(),
                  Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.securityGreen)),
                ],
              ),
              const Spacer(),
              Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
              Text('Ready', style: AppTypography.bodySm.copyWith(color: AppColors.securityGreen)),
            ],
          ),
        ),
      );
  }
}

class _RecentTransferRow extends StatelessWidget {
  const _RecentTransferRow({required this.record, required this.delay});
  final TransferRecord record;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 8 * (1 - value)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)), child: Icon(record.fileCount > 1 ? Icons.folder_zip_outlined : Icons.insert_drive_file_outlined, color: AppColors.secondary)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
                  Text('${record.peerDevice.name} · ${FileSizeFormatter.format(record.totalSizeBytes)} · ${TimeFormatter.formatRelative(record.completedAt)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(record.isSuccess ? Icons.check_circle_outline : Icons.error_outline, size: 18, color: record.isSuccess ? AppColors.securityGreen : AppColors.error),
          ],
        ),
      ),
    );
  }
}

class _RadarRing extends StatelessWidget {
  const _RadarRing({required this.progress, required this.size});
  final double progress;
  final double size;
  @override
  Widget build(BuildContext context) => Opacity(opacity: (1 - progress) * 0.3, child: Transform.scale(scale: 0.55 + progress * 0.45, child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.secondary.withValues(alpha: 0.65), width: 1)))));
}