import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../services/device_service/lan_device_service.dart';
import '../../services/network_service/tcp_transfer_transport.dart';

class NewPhoneReadyScreen extends StatefulWidget {
  const NewPhoneReadyScreen({super.key});
  @override
  State<NewPhoneReadyScreen> createState() => _NewPhoneReadyScreenState();
}

class _NewPhoneReadyScreenState extends State<NewPhoneReadyScreen> {
  static const _uuid = Uuid();
  final _receiver = TcpTransferReceiver();
  final _deviceService = LanDeviceService();
  StreamSubscription<IncomingTransferProgress>? _subscription;
  String? _payload;
  IncomingTransferProgress? _progress;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _subscription = _receiver.progressStream.listen((progress) {
      if (mounted) setState(() => _progress = progress);
    });
    _start();
  }

  Future<void> _start() async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      _receiver.outputDirectory = Directory('${documents.path}${Platform.pathSeparator}new_phone_files');
      final port = await _receiver.start();
      await _deviceService.startAdvertising();
      final host = await _localAddress();
      if (mounted) {
        setState(() => _payload = 'flowsend://new-phone?session=${_uuid.v4()}&host=$host&port=$port');
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<String> _localAddress() async {
    final interfaces = await NetworkInterface.list(includeLoopback: false, includeLinkLocal: false, type: InternetAddressType.IPv4);
    for (final interface in interfaces) {
      if (interface.addresses.isNotEmpty) return interface.addresses.first.address;
    }
    return '';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _receiver.dispose();
    _deviceService.stopAdvertising();
    _deviceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface), onPressed: () => context.pop()), title: const Text('New Phone')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        Text('Ready for your old phone', textAlign: TextAlign.center, style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface)),
        const SizedBox(height: AppSpacing.xs),
        Text('Scan this QR using FlowSend on your old phone.', textAlign: TextAlign.center, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null)
          Text('Could not start receiver. Make sure local network access is available.', textAlign: TextAlign.center, style: AppTypography.bodyMd.copyWith(color: AppColors.error))
        else if (_payload == null)
          const Center(child: CircularProgressIndicator(color: AppColors.secondary))
        else
          Center(child: Container(color: Colors.white, padding: const EdgeInsets.all(AppSpacing.md), child: QrImageView(data: _payload!, version: QrVersions.auto, size: 250))),
        const SizedBox(height: AppSpacing.lg),
        if (progress != null)
          Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(progress.isComplete ? 'Migration complete' : 'Receiving files', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)), const SizedBox(height: AppSpacing.sm), LinearProgressIndicator(value: progress.isComplete ? 1 : null), const SizedBox(height: AppSpacing.sm), Text(progress.fileName, style: AppTypography.labelMd.copyWith(color: AppColors.secondary))]))
        else
          Text('Keep this screen open while your old phone connects.', textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
      ])),
    );
  }
}
