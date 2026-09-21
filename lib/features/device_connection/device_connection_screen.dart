import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/discovered_device.dart';
import '../../models/selected_file.dart';
import '../../services/connection_service/smart_connection_service.dart';
import '../../widgets/device_chip.dart';
import '../../routes/app_router.dart';

/// Device Connection Screen — matches Stitch device_connection design.
/// Shows handshake animation, security verification chips, auto-countdown.
class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({
    super.key,
    required this.files,
    required this.device,
  });

  final List<SelectedFile> files;
  final DiscoveredDevice device;

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _packetController;
  late final AnimationController _fillController;
  late final Animation<double> _fillAnim;

  bool _isConnected = false;
  int _countdown = 2;
  Timer? _countdownTimer;
  Timer? _connectTimer;
  DiscoveredDevice _connectedDevice = const DiscoveredDevice(
    id: '',
    name: '',
    platform: DevicePlatform.unknown,
    status: DeviceStatus.offline,
  );
  String? _connectionError;

  bool get _isWifiDirect => widget.device.connectionMethod == ConnectionMethod.wifiDirect;

  String get _statusTitle => _isConnected
      ? '${widget.device.name} Connected'
      : 'Connecting to ${widget.device.name}...';

  String get _statusSubtitle {
    if (_connectionError != null) return _connectionError!;
    if (_isConnected) {
      return _isWifiDirect ? '⚡ Direct connection · No internet required' : 'Cryptographic channel locked';
    }
    return _isWifiDirect ? 'Establishing direct device-to-device link' : 'Negotiating direct peer tunnel';
  }

  @override
  void initState() {
    super.initState();
    _connectedDevice = widget.device;

    _packetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fillAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOut),
    );

    if (_isWifiDirect) {
      _connectViaSmartConnection();
    } else {
      // Same-Wi-Fi devices already have a reachable address — keep the
      // existing lightweight handshake animation unchanged.
      _connectTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() => _isConnected = true);
          _fillController.forward();
          _startCountdown();
        }
      });
    }
  }

  Future<void> _connectViaSmartConnection() async {
    try {
      final resolved = await SmartConnectionService.instance.connect(widget.device);
      if (!mounted) return;
      setState(() {
        _connectedDevice = resolved;
        _isConnected = true;
      });
      _fillController.forward();
      _startCountdown();
    } on SmartConnectionException catch (error) {
      if (!mounted) return;
      setState(() => _connectionError = error.message);
    } on Object {
      if (!mounted) return;
      setState(() => _connectionError = 'Could not establish a direct connection to ${widget.device.name}.');
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          t.cancel();
          _navigateToTransfer();
        }
      });
    });
  }

  void _navigateToTransfer() {
    if (!mounted) return;
    context.pushReplacement(
      AppRoutes.activeTransfer,
      extra: {'files': widget.files, 'device': _connectedDevice},
    );
  }

  @override
  void dispose() {
    _packetController.dispose();
    _fillController.dispose();
    _countdownTimer?.cancel();
    _connectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _connectionError != null
              ? _buildErrorState()
              : Column(
            children: [
              // Status header
              _buildStatusHeader(),
              const SizedBox(height: AppSpacing.lg),

              // Connection visual
              _buildConnectionVisual(),
              const SizedBox(height: AppSpacing.lg),

              // Verification chips
              _buildVerificationChips(),
              const SizedBox(height: AppSpacing.md),

              // Subtext
              Text(
                _isWifiDirect
                    ? 'No Wi-Fi network required. Connected device-to-device.'
                    : 'Zero configuration required. Handshake completed in 0.2s.',
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Transfer progress pill
              _buildTransferPill(),
              const SizedBox(height: AppSpacing.md),

              // Cancel link
              TextButton(
                onPressed: _cancelConnection,
                child: Text(
                  'Cancel connection',
                  style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelConnection() {
    if (_isWifiDirect) {
      unawaited(SmartConnectionService.instance.cleanup());
    }
    if (mounted) context.pop();
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Icon(Icons.wifi_tethering_off, size: 48, color: AppColors.error),
        const SizedBox(height: AppSpacing.md),
        Text('Direct connection failed',
            style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(_connectionError!,
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () {
              setState(() => _connectionError = null);
              _connectViaSmartConnection();
            },
            child: const Text('Try again'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _cancelConnection,
          child: Text('Back', style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.onSurface),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          const SizedBox(width: 4),
          Text('Transfer Session',
              style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
        ],
      ),
      actions: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: AppSpacing.md),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: const Icon(Icons.person, size: 18, color: AppColors.onPrimary),
        ),
      ],
    );
  }

  Widget _buildStatusHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppSpacing.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PingDot(),
              const SizedBox(width: 6),
              Text('Cryptographic P2P Sync',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.secondary,
                    letterSpacing: 1.2,
                  )),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _statusTitle,
            key: ValueKey(_isConnected),
            style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isConnected ? Icons.check_circle : Icons.sync,
                key: ValueKey(_isConnected),
                color: _isConnected ? AppColors.secondaryContainer : AppColors.secondary,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _statusSubtitle,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: Stack(
        children: [
          // Ambient glows
          Positioned(top: -24, left: -24,
              child: Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: AppColors.primaryContainer.withValues(alpha: 0.2)))),
          Positioned(bottom: -24, right: -24,
              child: Container(width: 110, height: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: AppColors.secondaryContainer.withValues(alpha: 0.2)))),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sender node
              _DeviceNode(
                label: 'iPhone 15 Pro',
                sublabel: 'Local Host',
                platform: DevicePlatform.ios,
                isActive: true,
              ),

              // Center: packet stream
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 32,
                        child: AnimatedBuilder(
                          animation: _packetController,
                          builder: (_, __) {
                            return CustomPaint(
                              size: const Size(double.infinity, 32),
                              painter: _PacketStreamPainter(
                                  progress: _packetController.value),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSpacing.full),
                        ),
                        child: Text('0.2s ping',
                            style: AppTypography.telemetryData.copyWith(color: AppColors.secondary)),
                      ),
                    ],
                  ),
                ),
              ),

              // Target node
              _DeviceNode(
                label: widget.device.name,
                sublabel: 'Target Device',
                platform: widget.device.platform,
                isActive: _isConnected,
                isTarget: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationChips() {
    final chips = [
      (Icons.fingerprint, AppColors.secondary, AppColors.primaryContainer, 'Device Verified', 'Hardware ID: #8F2A • Authenticated'),
      (Icons.enhanced_encryption, AppColors.tertiary, AppColors.tertiaryContainer, 'Secure Connection', 'TLS 1.3 / P2P Direct Tunnel'),
      (Icons.speed, AppColors.secondary, AppColors.secondaryContainer, 'Ready to Transfer', 'Bandwidth Allocated: ~120 MB/s'),
    ];

    return Column(
      children: chips.map((c) {
        final (icon, color, bg, title, subtitle) = c;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.base),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bg.withValues(alpha: 0.2),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
                      Text(subtitle, style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHighest,
                  ),
                  child: const Icon(Icons.check, size: 16, color: AppColors.secondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransferPill() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.full),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          // Fill bar
          AnimatedBuilder(
            animation: _fillAnim,
            builder: (_, __) => FractionallySizedBox(
              widthFactor: _fillAnim.value,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.secondaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.full),
                ),
              ),
            ),
          ),
          // Label
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _PingDot(),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isConnected
                          ? (_countdown > 0
                              ? 'Starting transfer in ${_countdown}s...'
                              : 'Payload dispatching now...')
                          : 'Connecting...',
                      key: ValueKey('$_isConnected$_countdown'),
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AppColors.onPrimaryContainer, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _DeviceNode extends StatelessWidget {
  const _DeviceNode({
    required this.label,
    required this.sublabel,
    required this.platform,
    required this.isActive,
    this.isTarget = false,
  });
  final String label;
  final String sublabel;
  final DevicePlatform platform;
  final bool isActive;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHigh,
            boxShadow: isActive
                ? [BoxShadow(color: AppColors.secondaryContainer.withValues(alpha: 0.4), blurRadius: 16)]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.3),
                      AppColors.secondaryContainer.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainer,
                ),
                child: DevicePlatformIcon(platform: platform, size: 30),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainer,
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppColors.secondaryContainer : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
        Text(sublabel, style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
      ],
    );
  }
}

class _PacketStreamPainter extends CustomPainter {
  _PacketStreamPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Rail
    final rail = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), rail);

    // Active gradient line
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryContainer, AppColors.secondaryContainer, AppColors.secondary],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), linePaint);

    // Packets
    final positions = [0.0, 0.33, 0.66];
    final colors = [AppColors.secondaryContainer, AppColors.primaryFixed, AppColors.secondary];
    for (var i = 0; i < positions.length; i++) {
      final x = ((progress + positions[i]) % 1.0) * size.width;
      final p = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, cy), 5, p);
    }
  }

  @override
  bool shouldRepaint(_PacketStreamPainter old) => old.progress != progress;
}

class _PingDot extends StatefulWidget {
  @override
  State<_PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<_PingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Transform.scale(
              scale: 1 + _c.value * 0.5,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: (1 - _c.value) * 0.75),
                ),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
