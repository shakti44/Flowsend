import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../models/discovered_device.dart';

/// Device status chip — compact pill badge for device status.
class DeviceStatusChip extends StatelessWidget {
  const DeviceStatusChip({super.key, required this.status});
  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  static (String, Color) _statusInfo(DeviceStatus status) => switch (status) {
        DeviceStatus.connected => ('Connected', AppColors.secondary),
        DeviceStatus.nearby => ('Nearby', AppColors.secondary),
        DeviceStatus.available => ('Available', AppColors.onSurfaceVariant),
        DeviceStatus.offline => ('Offline', AppColors.outline),
      };
}

/// Platform icon for a device.
class DevicePlatformIcon extends StatelessWidget {
  const DevicePlatformIcon({
    super.key,
    required this.platform,
    this.size = 26,
    this.color,
  });

  final DevicePlatform platform;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      _iconForPlatform(platform),
      size: size,
      color: color ?? AppColors.secondary,
    );
  }

  static IconData _iconForPlatform(DevicePlatform p) => switch (p) {
        DevicePlatform.macos => Icons.laptop_mac,
        DevicePlatform.ios => Icons.smartphone,
        DevicePlatform.android => Icons.phone_android,
        DevicePlatform.windows => Icons.desktop_windows,
        DevicePlatform.linux => Icons.computer,
        DevicePlatform.unknown => Icons.devices,
      };
}

/// Security verification pill — shows E2EE status.
class SecurityPill extends StatefulWidget {
  const SecurityPill({super.key, this.isActive = true});
  final bool isActive;

  @override
  State<SecurityPill> createState() => _SecurityPillState();
}

class _SecurityPillState extends State<SecurityPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryFixedDim,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryFixedDim
                        .withValues(alpha: 0.4 + _pulse.value * 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.isActive ? 'Active' : 'Inactive',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
