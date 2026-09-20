import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/discovered_device.dart';
import '../../routes/app_router.dart';

class EventJoinScanScreen extends StatefulWidget {
  const EventJoinScanScreen({super.key});
  @override
  State<EventJoinScanScreen> createState() => _EventJoinScanScreenState();
}

class _EventJoinScanScreenState extends State<EventJoinScanScreen> {
  bool _handled = false;
  void _handle(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    final uri = raw == null ? null : Uri.tryParse(raw);
    if (uri?.scheme != 'flowsend' || uri?.host != 'event') return;
    final host = uri!.queryParameters['host'];
    final port = int.tryParse(uri.queryParameters['port'] ?? '');
    if (host == null || host.isEmpty || port == null) return;
    _handled = true;
    context.pushReplacement(AppRoutes.eventContribution, extra: DiscoveredDevice(id: uri.queryParameters['session'] ?? host, name: uri.queryParameters['name'] ?? 'Event collection', platform: DevicePlatform.android, status: DeviceStatus.connected, address: host, port: port, protocolInfo: 'Event Rescue · Direct local connection'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: const Text('Join Event'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Scan the Event Rescue QR code',
                textAlign: TextAlign.center,
                style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: MobileScanner(onDetect: _handle),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Your files stay on your device until you choose to contribute them.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
