import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../widgets/flowsend_logo.dart';
import '../../routes/app_router.dart';

class CrossPlatformScreen extends StatefulWidget {
  const CrossPlatformScreen({super.key});
  @override
  State<CrossPlatformScreen> createState() => _CrossPlatformScreenState();
}

class _CrossPlatformScreenState extends State<CrossPlatformScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedIndex;

  static const _platforms = [
    (Icons.android, 'Android', true),
    (Icons.phone_iphone, 'iPhone / iPad', false),
    (Icons.laptop_windows, 'Windows', false),
    (Icons.desktop_mac, 'macOS', false),
    (Icons.language, 'Web Browser', false),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (!_platforms[index].$3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_platforms[index].$2} support is coming soon.')),
      );
      return;
    }
    setState(() => _selectedIndex = index);
    context.push(AppRoutes.selectFiles);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Cross-Platform', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('One FlowSend. Every device.', textAlign: TextAlign.center, style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: AppSpacing.xs),
            Text('Choose a supported destination platform.', textAlign: TextAlign.center, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 188, height: 188, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)))),
                    Container(width: 142, height: 142, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerLow, border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.55)), boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.2), blurRadius: 30)])),
                    const FlowSendLogoOrb(size: 92),
                    for (var index = 0; index < _platforms.length; index++) _orbitItem(index),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < _platforms.length; index++) _platformTile(index),
          ],
        ),
      ),
    );
  }

  Widget _orbitItem(int index) {
    final angle = index * math.pi * 2 / _platforms.length - math.pi / 2;
    final selected = _selectedIndex == index;
    return Transform.translate(
      offset: Offset(math.cos(angle) * 92, math.sin(angle) * 92),
      child: GestureDetector(
        onTap: () => _select(index),
        child: Container(
          width: selected ? 52 : 44,
          height: selected ? 52 : 44,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerHigh, border: Border.all(color: selected ? AppColors.secondary : AppColors.outlineVariant, width: selected ? 2 : 1)),
          child: Icon(_platforms[index].$1, size: 23, color: _platforms[index].$3 ? AppColors.secondary : AppColors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _platformTile(int index) {
    final supported = _platforms[index].$3;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => _select(index),
        tileColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(_platforms[index].$1, color: supported ? AppColors.secondary : AppColors.onSurfaceVariant),
        title: Text(_platforms[index].$2, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
        subtitle: Text(supported ? 'Nearby FlowSend devices' : 'Coming soon', style: AppTypography.bodySm.copyWith(color: supported ? AppColors.securityGreen : AppColors.onSurfaceVariant)),
        trailing: Icon(supported ? Icons.chevron_right : Icons.lock_outline, color: AppColors.onSurfaceVariant, size: 20),
      ),
    );
  }
}
