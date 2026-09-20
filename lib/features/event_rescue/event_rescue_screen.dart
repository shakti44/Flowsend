import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../services/device_service/lan_device_service.dart';
import '../../services/network_service/tcp_transfer_transport.dart';

class EventRescueScreen extends StatefulWidget {
  const EventRescueScreen({super.key});
  @override
  State<EventRescueScreen> createState() => _EventRescueScreenState();
}

class _EventRescueScreenState extends State<EventRescueScreen> {
  static const _uuid = Uuid();
  final _nameController = TextEditingController(text: 'New Event');
  final _receiver = TcpTransferReceiver(avoidOverwrites: true);
  final _deviceService = LanDeviceService();
  StreamSubscription<IncomingTransferProgress>? _subscription;
  final _contributors = <String>{};
  final _receivedPaths = <String>{};
  String? _payload;
  int _bytes = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _subscription = _receiver.progressStream.listen((progress) {
      if (!mounted) return;
      setState(() {
        if (progress.sessionId.isNotEmpty) _contributors.add(progress.sessionId);
        _bytes = progress.totalBytesTransferred;
        _receivedPaths.addAll(progress.receivedPaths);
      });
    });
    _start();
  }

  Future<void> _start() async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      final eventId = _uuid.v4();
      _receiver.outputDirectory = Directory('${documents.path}${Platform.pathSeparator}events${Platform.pathSeparator}$eventId');
      final port = await _receiver.start();
      await _deviceService.startAdvertising();
      final host = await _localAddress();
      if (mounted) setState(() => _payload = 'flowsend://event?session=$eventId&host=$host&port=$port&name=${Uri.encodeComponent(_nameController.text)}');
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
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface), onPressed: () => context.pop()), title: const Text('Event Rescue')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        TextField(controller: _nameController, onChanged: (_) => setState(() {}), style: AppTypography.labelLg.copyWith(color: AppColors.onSurface), decoration: InputDecoration(labelText: 'Event name', prefixIcon: const Icon(Icons.event_outlined), filled: true, fillColor: AppColors.surfaceContainerLow, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: AppSpacing.md),
        Text(_nameController.text, textAlign: TextAlign.center, style: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface)),
        const SizedBox(height: AppSpacing.xs),
        Text('Everyone contributes. FlowSend cleans it up.', textAlign: TextAlign.center, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null)
          Text('Could not start the local event receiver.', textAlign: TextAlign.center, style: AppTypography.bodyMd.copyWith(color: AppColors.error))
        else if (_payload == null)
          const Center(child: CircularProgressIndicator(color: AppColors.secondary))
        else ...[
          Center(child: Container(color: Colors.white, padding: const EdgeInsets.all(AppSpacing.md), child: QrImageView(data: _payload!, version: QrVersions.auto, size: 220))),
          const SizedBox(height: AppSpacing.sm),
          Text('Scan this code with FlowSend on each contributor phone.', textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        ],
        const SizedBox(height: AppSpacing.lg),
        _StatCard(icon: Icons.people_outline, label: 'Contributors', value: '${_contributors.length}'),
        _StatCard(icon: Icons.photo_library_outlined, label: 'Files collected', value: '${_receivedPaths.length}'),
        _StatCard(icon: Icons.data_usage, label: 'Total size', value: FileSizeFormatter.format(_bytes)),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.fact_check_outlined), label: const Text('Review Collection')),
      ])),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(icon, color: AppColors.secondary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant))), Text(value, style: AppTypography.telemetryData.copyWith(color: AppColors.onSurface))])));
}
