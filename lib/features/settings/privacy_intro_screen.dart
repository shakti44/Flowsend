import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../widgets/flowsend_logo.dart';

class PrivacyIntroScreen extends StatelessWidget {
  const PrivacyIntroScreen({super.key, required this.onContinue, required this.onPrivacyPolicy});
  final VoidCallback onContinue;
  final VoidCallback onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlowSendLogoOrb(size: 104),
              const SizedBox(height: AppSpacing.lg),
              Text('FlowSend', style: AppTypography.headlineLg.copyWith(color: AppColors.onSurface)),
              const SizedBox(height: AppSpacing.xs),
              Text('Built for private transfers', style: AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.lg),
              _IntroLine(icon: Icons.lock_outline, label: 'Direct device transfer'),
              _IntroLine(icon: Icons.folder_open_outlined, label: 'You choose what to share'),
              _IntroLine(icon: Icons.verified_outlined, label: 'Transfer verification'),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'FlowSend needs certain device permissions only when required for sending, receiving, discovering devices, or saving files.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(onPressed: onContinue, child: const Text('Continue')),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: onPrivacyPolicy, child: const Text('Privacy Policy')),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroLine extends StatelessWidget {
  const _IntroLine({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
          ],
        ),
      );
}
