import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_spacing.dart';

/// Trusted Devices Screen — stub for Phase 6.
class TrustedDevicesScreen extends StatelessWidget {
  const TrustedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('My Devices', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.devices, size: 56, color: AppColors.secondary),
            SizedBox(height: AppSpacing.md),
            Text('No trusted devices', style: TextStyle(color: AppColors.onSurface)),
          ],
        ),
      ),
    );
  }
}
