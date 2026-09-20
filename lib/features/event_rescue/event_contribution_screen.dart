import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/discovered_device.dart';
import '../../routes/app_router.dart';
import '../file_selection/file_selection_screen.dart';

class EventContributionScreen extends StatelessWidget {
  const EventContributionScreen({super.key, required this.targetDevice});
  final DiscoveredDevice targetDevice;
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.surface, appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface), onPressed: () => context.pop()), title: const Text('Contribute')), body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [Text(targetDevice.name, style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface)), const SizedBox(height: AppSpacing.xs), Text('Choose photos, videos, or files to add to this local collection.', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)), const SizedBox(height: AppSpacing.lg), for (final category in FileSelectionCategory.values.where((item) => item != FileSelectionCategory.folders)) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: ListTile(onTap: () => context.push(AppRoutes.selectFiles, extra: {'category': category, 'targetDevice': targetDevice}), tileColor: AppColors.surfaceContainerLow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: Icon(category.icon, color: AppColors.secondary), title: Text(category.label, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)), trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant))), const SizedBox(height: AppSpacing.md), Text('Exact duplicates can be skipped by Smart Handoff before contribution.', textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant))]));
}
