import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_typography.dart';
import 'flowsend_logo.dart';

/// App header bar — matches the fixed Stitch header with logo, title,
/// settings button, and avatar.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title = 'FlowSend',
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.showSettings = true,
    this.onSettings,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showSettings;
  final VoidCallback? onSettings;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        height: 64 + MediaQuery.of(context).padding.top,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              // Left: logo + title or back button
              if (showBack)
                IconButton(
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.onSurface,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainer,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                )
              else ...[
                const FlowSendLogo(size: 32),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                        height: 1,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!.toUpperCase(),
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                  ],
                ),
              ],

              const Spacer(),

              // Right: custom actions or defaults
              if (actions != null)
                ...actions!
              else ...[
                if (showSettings)
                  IconButton(
                    onPressed: onSettings,
                    icon: const Icon(Icons.tune, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.onPrimary,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
