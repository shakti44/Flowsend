import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';

/// Bottom navigation bar — matches the Stitch 4-tab nav:
/// Home / Transfers / Devices / Settings
class FlowSendBottomNav extends StatelessWidget {
  const FlowSendBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    _NavTab(icon: Icons.swap_horiz, label: 'Home'),
    _NavTab(icon: Icons.sync_alt, label: 'Transfers'),
    _NavTab(icon: Icons.radar, label: 'Devices'),
    _NavTab(icon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final isSelected = i == currentIndex;
              final tab = _tabs[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.surfaceContainerHigh.withValues(alpha: 0.6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 24,
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: AppTypography.labelSm.copyWith(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
