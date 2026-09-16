import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_spacing.dart';

/// Settings Screen — Phase 1 stub.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _maxSpeed = 'Auto';
  String _autoResume = 'On';
  String _integrity = 'Always';
  String _qrTimeout = '24h';
  bool _useMockServices = false;
  bool _debugLogs = false;

  Future<void> _choose(String title, List<String> options, String current, ValueChanged<String> onSelected) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(title, style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            ),
            for (final option in options)
              RadioListTile<String>(
                value: option,
                groupValue: current,
                activeColor: AppColors.secondary,
                title: Text(option, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
                onChanged: (value) => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => onSelected(selected));
  }

  Future<void> _showEncryptionInfo() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Encryption', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
        content: Text(
          'FlowSend uses the configured LAN transport and verifies received files with SHA-256 before completion.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

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
        title: Text('Settings', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SettingsSection(
            title: 'TRANSFER',
            items: [
              _SettingsItem(icon: Icons.speed, label: 'Max Transfer Speed', value: _maxSpeed, onTap: () => _choose('Max Transfer Speed', ['Auto', '25 MB/s', '50 MB/s', '100 MB/s'], _maxSpeed, (value) => _maxSpeed = value)),
              _SettingsItem(icon: Icons.pause_circle_outline, label: 'Auto-Resume', value: _autoResume, onTap: () => _choose('Auto-Resume', ['On', 'Off'], _autoResume, (value) => _autoResume = value)),
              _SettingsItem(icon: Icons.verified_user, label: 'Integrity Verification', value: _integrity, onTap: () => _choose('Integrity Verification', ['Always', 'On completion', 'Off'], _integrity, (value) => _integrity = value)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsSection(
            title: 'SECURITY',
            items: [
              _SettingsItem(icon: Icons.lock_outline, label: 'Encryption', value: 'LAN + SHA-256', onTap: _showEncryptionInfo),
              _SettingsItem(icon: Icons.devices, label: 'Trusted Devices', value: '0', onTap: () => context.push('/devices')),
              _SettingsItem(icon: Icons.qr_code, label: 'QR Code Timeout', value: _qrTimeout, onTap: () => _choose('QR Code Timeout', ['1h', '6h', '24h'], _qrTimeout, (value) => _qrTimeout = value)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsSection(
            title: 'DEVELOPER',
            items: [
              _SettingsItem(icon: Icons.science_outlined, label: 'Use Mock Services', value: _useMockServices ? 'On' : 'Off', onTap: () => setState(() => _useMockServices = !_useMockServices)),
              _SettingsItem(icon: Icons.bug_report_outlined, label: 'Debug Logs', value: _debugLogs ? 'On' : 'Off', onTap: () => setState(() => _debugLogs = !_debugLogs)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(title,
              style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.base),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  item,
                  if (!isLast)
                    const Divider(height: 1, color: AppColors.outlineVariant, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.secondary, size: 22),
      title: Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTypography.telemetryData.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
