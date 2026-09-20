import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../services/device_service/lan_device_service.dart';
import '../../services/network_service/tcp_transfer_transport.dart';

class CollectScreen extends StatefulWidget {
  const CollectScreen({super.key});

  @override
  State<CollectScreen> createState() => _CollectScreenState();
}

class _CollectScreenState extends State<CollectScreen> {
  static const _uuid = Uuid();
  final _receiver = TcpTransferReceiver();
  final _deviceService = LanDeviceService();
  final _titleController = TextEditingController(text: 'New Collection');
  StreamSubscription<IncomingTransferProgress>? _progressSubscription;
  IncomingTransferProgress? _progress;
  String? _sessionId;
  int? _port;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _progressSubscription = _receiver.progressStream.listen((progress) {
      if (mounted) setState(() => _progress = progress);
    });
    _startCollection();
  }

  Future<void> _startCollection() async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      _receiver.outputDirectory = Directory(
        '${documents.path}${Platform.pathSeparator}collections',
      );
      final port = await _receiver.start();
      await _deviceService.startAdvertising();
      if (mounted) {
        setState(() {
          _sessionId = _uuid.v4();
          _port = port;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  String get _payload =>
      'flowsend://collect?session=$_sessionId&port=$_port&name=${Uri.encodeComponent(_titleController.text)}';

  @override
  void dispose() {
    _titleController.dispose();
    _progressSubscription?.cancel();
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
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        elevation: 0,
        title: Text('Collect', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextField(
              controller: _titleController,
              style: AppTypography.labelLg.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                labelText: 'Collection name',
                prefixIcon: const Icon(Icons.collections_outlined),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null)
              _InfoCard(title: 'Collection unavailable', body: 'Could not start the local collection receiver.'),
            if (_error == null && _sessionId != null) ...[
              Text('Scan to join this collection', textAlign: TextAlign.center, style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: QrImageView(data: _payload, version: QrVersions.auto, size: 210),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Devices must be on the same local network. The QR contains temporary session metadata only.', textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.lg),
              _SummaryRow(label: 'Status', value: _port == null ? 'Starting...' : 'Ready to collect'),
              _SummaryRow(label: 'Collection status', value: progress == null ? 'Waiting for files' : 'Receiving files'),
              _SummaryRow(label: 'Total size', value: FileSizeFormatter.format(progress?.totalBytesTransferred ?? 0)),
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(value: progress.isComplete ? 1 : null, minHeight: 8, borderRadius: BorderRadius.circular(AppSpacing.full)),
                const SizedBox(height: AppSpacing.sm),
                Text(progress.isComplete ? 'Latest contribution verified' : 'Receiving ${progress.fileName}', style: AppTypography.labelMd.copyWith(color: AppColors.secondary)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        ]),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(children: [Expanded(child: Text(label, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant))), Text(value, style: AppTypography.telemetryData.copyWith(color: AppColors.onSurface))]),
      );
}
