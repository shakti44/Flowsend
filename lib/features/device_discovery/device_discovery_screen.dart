import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/discovered_device.dart';
import '../../models/selected_file.dart';
import '../../services/device_service/device_service.dart';
import '../../services/device_service/lan_device_service.dart';
import '../../widgets/radar_canvas.dart';
import '../../widgets/device_chip.dart';
import '../../routes/app_router.dart';
import 'transfer_session_screen.dart';

/// Device Discovery Screen — matches Stitch choose_a_device design.
/// Radar canvas, progressive device list, QR + Transfer Link alternatives.
class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({
    super.key,
    required this.selectedFiles,
  });

  final List<SelectedFile> selectedFiles;

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> {
  final DeviceService _deviceService = LanDeviceService();
  final List<DiscoveredDevice> _devices = [];
  final Set<String> _selectedDeviceIds = {};
  bool _isScanning = false;

  int get _totalBytes =>
      widget.selectedFiles.fold(0, (s, f) => s + f.sizeBytes);

  @override
  void initState() {
    super.initState();
    _startDiscovery();
    _deviceService.devicesStream.listen((devices) {
      if (mounted) setState(() => _devices
        ..clear()
        ..addAll(devices));
    });
  }

  Future<void> _startDiscovery() async {
    if (!mounted) return;
    setState(() => _isScanning = true);
    await _deviceService.startDiscovery();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _refreshRadar() async {
    _devices.clear();
    setState(() {});
    await _startDiscovery();
  }

  void _selectDevice(DiscoveredDevice device) {
    _deviceService.stopDiscovery();
    context.push(
      AppRoutes.smartTransferCheck,
      extra: {'files': widget.selectedFiles, 'devices': [device]},
    );
  }

  void _toggleDevice(DiscoveredDevice device) {
    setState(() {
      if (_selectedDeviceIds.contains(device.id)) {
        _selectedDeviceIds.remove(device.id);
      } else {
        _selectedDeviceIds.add(device.id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedDeviceIds.length == _devices.length) {
        _selectedDeviceIds.clear();
      } else {
        _selectedDeviceIds
          ..clear()
          ..addAll(_devices.map((device) => device.id));
      }
    });
  }

  void _startMultiDeviceTransfer() {
    final selected = _devices
        .where((device) => _selectedDeviceIds.contains(device.id))
        .toList();
    if (selected.isEmpty) return;
    _deviceService.stopDiscovery();
    context.push(
      AppRoutes.smartTransferCheck,
      extra: {'files': widget.selectedFiles, 'devices': selected},
    );
  }

  @override
  void dispose() {
    _deviceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(context),
            const SizedBox(height: AppSpacing.sm),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    // Radar canvas card
                    _buildRadarCard(),
                    const SizedBox(height: AppSpacing.md),

                    // Device list
                    _buildDeviceList(),
                    const SizedBox(height: AppSpacing.md),

                    // Alternative methods
                    _buildAlternativeMethods(),
                    const SizedBox(height: AppSpacing.sm),

                    // Payload summary banner
                    _buildPayloadBanner(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          // Back button with label
          SizedBox(
            width: 76,
            child: OutlinedButton.icon(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                foregroundColor: AppColors.onSurface,
                minimumSize: const Size(76, 48),
                maximumSize: const Size(76, 48),
              ),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text('Files', style: AppTypography.labelMd),
            ),
          ),

          const Spacer(),

          Column(
            children: [
              Text('Choose Device',
                  style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDot(color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text('Radar Active',
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Refresh
          IconButton(
            onPressed: _refreshRadar,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              shape: const CircleBorder(),
              fixedSize: const Size(40, 40),
            ),
            icon: AnimatedRotation(
              turns: _isScanning ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: const Icon(Icons.refresh, size: 20, color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.base),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Ambient glows
          Positioned(
            top: -24, left: -24,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.20),
              ),
            ),
          ),
          Positioned(
            bottom: -20, right: -20,
            child: Container(
              width: 132, height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryContainer.withValues(alpha: 0.15),
              ),
            ),
          ),

          Column(
            children: [
              const RadarCanvas(size: 144),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _isScanning ? 'Finding nearby devices...' : 'Scan complete',
                style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
              ),
              Text(
                'Searching via Ultra-Wideband & Wi-Fi Direct',
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppSpacing.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text('802.11be ready',
                        style: AppTypography.telemetryData.copyWith(color: AppColors.secondary)),
                    Container(
                        width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.outlineVariant)),
                    Text('P2P Mesh v4.2',
                        style: AppTypography.telemetryData.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              Text(
                'DISCOVERED IN RANGE (${_devices.length})',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (_devices.isNotEmpty)
                TextButton(
                  onPressed: _toggleSelectAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(
                    _selectedDeviceIds.length == _devices.length
                        ? 'Clear all'
                        : 'Select all',
                    style: AppTypography.labelSm.copyWith(color: AppColors.primary),
                  ),
                )
              else
                Text('Tap to send',
                    style: AppTypography.labelSm.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_devices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 2),
                  const SizedBox(height: AppSpacing.md),
                  Text('Scanning for devices...',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          )
        else
          ...(_devices.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _DeviceListItem(
                  device: d,
                  selected: _selectedDeviceIds.contains(d.id),
                  onTap: () => _selectDevice(d),
                  onToggle: () => _toggleDevice(d),
                ),
              ))),
        if (_selectedDeviceIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _startMultiDeviceTransfer,
                icon: const Icon(Icons.send_to_mobile),
                label: Text(
                  'Start Transfer · ${_selectedDeviceIds.length} device${_selectedDeviceIds.length == 1 ? '' : 's'}',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlternativeMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALTERNATIVE TRANSFER METHODS',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _AlternativeMethodButton(
                icon: Icons.qr_code_scanner,
                iconColor: AppColors.secondary,
                title: 'Scan QR Code',
                subtitle: 'Direct camera pairing',
                onTap: () => context.push(
                  AppRoutes.transferSession,
                  extra: {
                    'files': widget.selectedFiles,
                    'mode': TransferSessionMode.qr,
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AlternativeMethodButton(
                icon: Icons.link,
                iconColor: AppColors.primary,
                title: 'Transfer Link',
                subtitle: 'Web share payload',
                badge: '24h link',
                onTap: () => context.push(
                  AppRoutes.transferSession,
                  extra: {
                    'files': widget.selectedFiles,
                    'mode': TransferSessionMode.link,
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPayloadBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainer,
            ),
            child: const Icon(Icons.folder_zip_outlined, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sending ${widget.selectedFiles.length} file${widget.selectedFiles.length == 1 ? '' : 's'} (${FileSizeFormatter.format(_totalBytes)})',
                  style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
                ),
                Row(
                  children: [
                    const Icon(Icons.lock, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text('End-to-end encrypted',
                        style: AppTypography.bodySm.copyWith(color: AppColors.secondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.secondaryContainer)),
              const SizedBox(width: 6),
              Text('ChaCha20', style: AppTypography.telemetryData.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _DeviceListItem extends StatelessWidget {
  const _DeviceListItem({
    required this.device,
    required this.selected,
    required this.onTap,
    required this.onToggle,
  });
  final DiscoveredDevice device;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
          border: device.status == DeviceStatus.connected
              ? const Border(left: BorderSide(color: AppColors.secondaryContainer, width: 4))
              : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.base),
                boxShadow: device.status == DeviceStatus.connected
                    ? [BoxShadow(color: AppColors.secondaryContainer.withValues(alpha: 0.2), blurRadius: 16)]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  DevicePlatformIcon(
                    platform: device.platform,
                    size: 26,
                    color: device.status == DeviceStatus.connected
                        ? AppColors.secondary
                        : device.status == DeviceStatus.nearby
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceContainer,
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: device.status == DeviceStatus.connected
                                ? AppColors.secondary
                                : device.status == DeviceStatus.nearby
                                    ? AppColors.secondary
                                    : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          device.name,
                          style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      DeviceStatusChip(status: device.status),
                    ],
                  ),
                  if (device.protocolInfo != null)
                    Text(
                      device.protocolInfo!,
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Existing arrow keeps the single-device flow; checkbox adds the
            // independent multi-device flow.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: device.status == DeviceStatus.connected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainerHighest,
                    boxShadow: device.status == DeviceStatus.connected
                        ? [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.35), blurRadius: 14)]
                        : null,
                  ),
                  child: Icon(
                    device.status == DeviceStatus.connected ? Icons.arrow_forward : Icons.send,
                    size: 20,
                    color: device.status == DeviceStatus.connected
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Checkbox(
                  value: selected,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.secondary,
                  checkColor: AppColors.onSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlternativeMethodButton extends StatelessWidget {
  const _AlternativeMethodButton({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainer,
                  ),
                  child: Icon(icon, size: 22, color: iconColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(title, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
                Text(subtitle, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.full),
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onTertiaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _a.value),
        ),
      ),
    );
  }
}
