import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/discovered_device.dart';
import '../../routes/app_router.dart';

class NewPhoneScanScreen extends StatefulWidget {
  const NewPhoneScanScreen({super.key});
  @override
  State<NewPhoneScanScreen> createState() => _NewPhoneScanScreenState();
}

class _NewPhoneScanScreenState extends State<NewPhoneScanScreen> {
  bool _handled = false;

  void _handleCapture(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    final uri = Uri.tryParse(raw);
    if (uri?.scheme != 'flowsend' || uri?.host != 'new-phone') return;
    final host = uri?.queryParameters['host'];
    final port = int.tryParse(uri?.queryParameters['port'] ?? '');
    if (host == null || host.isEmpty || port == null) return;
    _handled = true;
    context.pushReplacement(
      AppRoutes.newPhoneContent,
      extra: DiscoveredDevice(
        id: uri?.queryParameters['session'] ?? host,
        name: 'New Phone',
        platform: DevicePlatform.android,
        status: DeviceStatus.connected,
        address: host,
        port: port,
        protocolInfo: 'New Phone · Direct local connection',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface), onPressed: () => context.pop()), title: const Text('Scan New Phone')),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('Scan the QR shown on your new phone', textAlign: TextAlign.center, style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface))),
        Expanded(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: ClipRRect(borderRadius: BorderRadius.circular(18), child: MobileScanner(onDetect: _handleCapture)))),
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('The code contains temporary connection details only.', textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant))),
      ])),
    );
  }
}
