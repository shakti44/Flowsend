import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../routes/app_router.dart';
import '../file_selection/file_selection_screen.dart';

class NewPhoneScreen extends StatelessWidget {
  const NewPhoneScreen({super.key});

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
        title: Text('Move to New Phone', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Icon(Icons.phone_android_outlined, color: AppColors.secondary, size: 52),
          const SizedBox(height: AppSpacing.md),
          Text('Bring your essentials with you.', textAlign: TextAlign.center, style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.xs),
          Text('Choose what to move. Smart Handoff will check the new phone for files that already exist before transferring.', textAlign: TextAlign.center, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),
          _CategoryButton(icon: Icons.photo_library_outlined, title: 'Photos', subtitle: 'Camera photos and images', category: FileSelectionCategory.photos),
          _CategoryButton(icon: Icons.video_library_outlined, title: 'Videos', subtitle: 'Large videos and recordings', category: FileSelectionCategory.videos),
          _CategoryButton(icon: Icons.description_outlined, title: 'Documents', subtitle: 'PDF, Office and text files', category: FileSelectionCategory.documents),
          _CategoryButton(icon: Icons.folder_outlined, title: 'Downloads & Files', subtitle: 'Choose any files or APKs', category: FileSelectionCategory.files),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.verified_outlined, color: AppColors.secondary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('Duplicates are reviewed before anything is sent. Nothing is deleted automatically.', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)))]),
          ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.icon, required this.title, required this.subtitle, required this.category});
  final IconData icon;
  final String title;
  final String subtitle;
  final FileSelectionCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => context.push(AppRoutes.selectFiles, extra: {'category': category}),
        tileColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppColors.secondary),
        title: Text(title, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
        subtitle: Text(subtitle, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
