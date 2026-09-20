import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../routes/app_router.dart';

class NewPhoneScreen extends StatelessWidget {
  const NewPhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface), onPressed: () => context.pop()),
        title: Text('Move to New Phone', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Icon(Icons.phone_android_outlined, color: AppColors.secondary, size: 58),
          const SizedBox(height: AppSpacing.md),
          Text('Move what matters.', textAlign: TextAlign.center, style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.xs),
          Text('Skip what is already there.', textAlign: TextAlign.center, style: AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),
          _RoleCard(icon: Icons.arrow_upward_rounded, title: 'This is my old phone', subtitle: 'Choose files to move to your new phone.', onTap: () => context.push(AppRoutes.newPhoneScan)),
          _RoleCard(icon: Icons.arrow_downward_rounded, title: 'This is my new phone', subtitle: 'Show a QR code and wait for your old phone.', onTap: () => context.push(AppRoutes.newPhoneReady)),
          const SizedBox(height: AppSpacing.md),
          Text('FlowSend only moves files you choose. It does not copy private app data, passwords, or system credentials.', textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          tileColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerHigh), child: Icon(icon, color: AppColors.secondary)),
          title: Text(title, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
          subtitle: Text(subtitle, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ),
      );
}
