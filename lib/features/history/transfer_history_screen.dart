import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/transfer_record.dart';
import '../../services/history_service.dart';

/// Transfer History Screen — stub for Phase 6.
class TransferHistoryScreen extends StatelessWidget {
  const TransferHistoryScreen({super.key});

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
        title: Text('Transfer History', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      ),
      body: FutureBuilder<List<TransferRecord>>(
        future: HistoryService().load(),
        builder: (context, snapshot) {
          final records = snapshot.data ?? const <TransferRecord>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            );
          }
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 56, color: AppColors.secondary),
                  SizedBox(height: AppSpacing.md),
                  Text('No transfers yet', style: TextStyle(color: AppColors.onSurface)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _HistoryRecordTile(record: records[index]),
          );
        },
      ),
    );
  }
}

class _HistoryRecordTile extends StatelessWidget {
  const _HistoryRecordTile({required this.record});

  final TransferRecord record;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.base)),
      leading: const CircleAvatar(
        backgroundColor: AppColors.surfaceContainerHigh,
        child: Icon(Icons.arrow_upward, color: AppColors.secondary),
      ),
      title: Text(record.fileName, style: const TextStyle(color: AppColors.onSurface)),
      subtitle: Text(
        '${record.peerDevice.name} · ${FileSizeFormatter.format(record.totalSizeBytes)}',
        style: const TextStyle(color: AppColors.onSurfaceVariant),
      ),
      trailing: Icon(
        record.isSuccess ? Icons.check_circle : Icons.error,
        color: record.isSuccess ? AppColors.secondary : AppColors.error,
      ),
    );
  }
}
