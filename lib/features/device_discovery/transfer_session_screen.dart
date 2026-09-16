import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/selected_file.dart';

class TransferSessionScreen extends StatefulWidget {
  const TransferSessionScreen({
    super.key,
    required this.files,
    required this.mode,
  });

  final List<SelectedFile> files;
  final TransferSessionMode mode;

  @override
  State<TransferSessionScreen> createState() => _TransferSessionScreenState();
}

enum TransferSessionMode { qr, link }

class _TransferSessionScreenState extends State<TransferSessionScreen> {
  static const _uuid = Uuid();
  late final String _sessionId;
  late final DateTime _expiresAt;

  String get _sessionPayload =>
      'flowsend://transfer?session=$_sessionId&expires=${_expiresAt.toUtc().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _sessionId = _uuid.v4();
    _expiresAt = DateTime.now().toUtc().add(const Duration(hours: 24));
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _sessionPayload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isQr = widget.mode == TransferSessionMode.qr;
    final totalBytes = widget.files.fold(0, (sum, file) => sum + file.sizeBytes);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isQr ? 'QR Transfer Session' : 'Transfer Link',
          style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(
                isQr ? 'Scan this code on the receiving device' : 'Share this link with the receiving device',
                style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'The session expires in 24 hours. File contents are not stored in the code or link.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isQr)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: Colors.white,
                  child: QrImageView(
                    data: _sessionPayload,
                    version: QrVersions.auto,
                    size: 240,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.base),
                  ),
                  child: SelectableText(
                    _sessionPayload,
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              _SummaryCard(fileCount: widget.files.length, totalBytes: totalBytes),
              const SizedBox(height: AppSpacing.md),
              if (!isQr)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy transfer link'),
                  ),
                ),
              if (isQr)
                Text(
                  'Waiting for the receiver to join this session',
                  style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.fileCount, required this.totalBytes});

  final int fileCount;
  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.base),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$fileCount file${fileCount == 1 ? '' : 's'} · ${FileSizeFormatter.format(totalBytes)}',
            style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}
