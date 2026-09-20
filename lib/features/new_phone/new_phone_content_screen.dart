import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/discovered_device.dart';
import '../file_selection/file_selection_screen.dart';
import '../../routes/app_router.dart';

class NewPhoneContentScreen extends StatelessWidget {
  const NewPhoneContentScreen({super.key, required this.targetDevice});
  final DiscoveredDevice targetDevice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface), onPressed: () => context.pop()), title: const Text('Choose what to move')),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        Text('Connected ✓', style: AppTypography.labelLg.copyWith(color: AppColors.securityGreen)),
        const SizedBox(height: AppSpacing.xs),
        Text('Ready to move files to ${targetDevice.name}', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.lg),
        for (final category in FileSelectionCategory.values.where((item) => item != FileSelectionCategory.folders))
          Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: ListTile(onTap: () => context.push(AppRoutes.selectFiles, extra: {'category': category, 'targetDevice': targetDevice}), tileColor: AppColors.surfaceContainerLow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: Icon(category.icon, color: AppColors.secondary), title: Text(category.label, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)), subtitle: Text('Choose accessible ${category.label.toLowerCase()} to transfer', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)), trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant))),
        Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('FlowSend moves only files you choose and verifies them after transfer.', textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant))),
      ]),
    );
  }
}
