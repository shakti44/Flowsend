import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  static const privacyPolicyUrl = String.fromEnvironment('FLOWSEND_PRIVACY_URL');
  static const termsUrl = String.fromEnvironment('FLOWSEND_TERMS_URL');
  static const supportEmail = String.fromEnvironment('FLOWSEND_SUPPORT_EMAIL');

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  late Future<List<_PermissionRow>> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = _readPermissions();
  }

  Future<List<_PermissionRow>> _readPermissions() async {
    final statuses = await Future.wait([
      Permission.nearbyWifiDevices.status,
      Permission.photos.status,
      Permission.videos.status,
    ]);
    return [
      _PermissionRow('Nearby devices', statuses[0]),
      _PermissionRow('Photos', statuses[1]),
      _PermissionRow('Videos', statuses[2]),
    ];
  }

  Future<void> _openConfigured(String value, String label) async {
    if (value.isEmpty) {
      _showMessage('$label is not configured yet.');
      return;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('Could not open $label.');
    }
  }

  Future<void> _contactSupport() async {
    if (PrivacySecurityScreen.supportEmail.isEmpty) {
      _showMessage('Support email is not configured yet.');
      return;
    }
    final uri = Uri(scheme: 'mailto', path: PrivacySecurityScreen.supportEmail);
    if (!await launchUrl(uri)) _showMessage('Could not open email.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Privacy & Security', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Your files. Your devices. Your control.', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),
          _InfoCard(icon: Icons.folder_open_outlined, title: 'Your files stay yours', body: 'FlowSend transfers files directly between devices. Your files are not uploaded to FlowSend servers during local transfers.'),
          _InfoCard(icon: Icons.compare_arrows, title: 'Direct transfers', body: 'FlowSend uses local device-to-device connectivity for transfers on the same network.'),
          _InfoCard(icon: Icons.file_present_outlined, title: 'File access', body: 'FlowSend accesses files when you choose files to send or when received files are saved.'),
          _InfoCard(icon: Icons.devices_other, title: 'Nearby devices', body: 'Nearby-device and local-network access helps FlowSend discover devices available for transfer.'),
          _InfoCard(icon: Icons.verified_outlined, title: 'Transfer verification', body: 'FlowSend computes SHA-256 hashes as part of its integrity checks for transferred files.'),
          _InfoCard(icon: Icons.delete_outline, title: 'Your control', body: 'FlowSend never automatically deletes your source files or received files.'),
          const SizedBox(height: AppSpacing.md),
          _sectionTitle('APP PERMISSIONS'),
          FutureBuilder<List<_PermissionRow>>(
            future: _permissions,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator(minHeight: 2);
              return Column(
                children: [
                  for (final row in snapshot.data!) _PermissionTile(row: row),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await openAppSettings();
                        if (mounted) setState(() => _permissions = _readPermissions());
                      },
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Manage Permissions'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle('PRIVACY LINKS'),
          _LinkTile('Privacy Policy', () => _openConfigured(PrivacySecurityScreen.privacyPolicyUrl, 'Privacy Policy')),
          _LinkTile('Terms of Service', () => _openConfigured(PrivacySecurityScreen.termsUrl, 'Terms of Service')),
          _LinkTile('Open Source Licenses', () => showLicensePage(context: context, applicationName: 'FlowSend')),
          _LinkTile('Contact Support', _contactSupport),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
        child: Text(text, style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.1)),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.secondary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Text(body, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ]),
            ),
          ],
        ),
      );
}

class _PermissionRow {
  const _PermissionRow(this.label, this.status);
  final String label;
  final PermissionStatus status;
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.row});
  final _PermissionRow row;

  @override
  Widget build(BuildContext context) {
    final allowed = row.status.isGranted || row.status.isLimited;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      leading: Icon(allowed ? Icons.check_circle_outline : Icons.info_outline, color: allowed ? AppColors.securityGreen : AppColors.onSurfaceVariant),
      title: Text(row.label, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
      trailing: Text(allowed ? 'Allowed' : row.status.name, style: AppTypography.telemetryData.copyWith(color: allowed ? AppColors.securityGreen : AppColors.onSurfaceVariant)),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        title: Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
      );
}
