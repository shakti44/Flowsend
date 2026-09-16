import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/discovered_device.dart';
import '../../models/duplicate_analysis.dart';
import '../../models/selected_file.dart';
import '../../services/transfer_service/duplicate_protection_service.dart';
import '../../services/transfer_service/smart_handoff_service.dart';
import '../../routes/app_router.dart';

class SmartTransferCheckScreen extends StatefulWidget {
  const SmartTransferCheckScreen({
    super.key,
    required this.files,
    required this.devices,
  });

  final List<SelectedFile> files;
  final List<DiscoveredDevice> devices;

  @override
  State<SmartTransferCheckScreen> createState() => _SmartTransferCheckScreenState();
}

class _SmartTransferCheckScreenState extends State<SmartTransferCheckScreen> {
  final _service = DuplicateProtectionService();
  final _handoffService = SmartHandoffService();
  final Map<String, DeviceDuplicateAnalysis> _analyses = {};
  double _completed = 0;
  Object? _error;
  bool _reviewing = false;

  bool get _isAnalyzing => _completed < widget.devices.length && _error == null;
  bool get _isMultiDevice => widget.devices.length > 1;
  Iterable<DuplicateFileAnalysis> get _allFiles => _analyses.values.expand((item) => item.files);
  int get _exactCount => _allFiles.where((item) => item.isExact).length;
  int get _possibleCount => _allFiles.where((item) => item.isPossible).length;
  int get _newCount => _allFiles.where((item) => item.status == DuplicateStatus.newFile || item.status == DuplicateStatus.largeFile).length;
  int get _largeCount => _allFiles.where((item) => item.status == DuplicateStatus.largeFile).length;
  int get _duplicateBytes => _allFiles.where((item) => item.isExact).fold(0, (sum, item) => sum + item.file.sizeBytes);

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    try {
      for (final device in widget.devices) {
        final result = await _service.analyze(
          files: widget.files,
          device: device,
          onProgress: (completed, total) {
            if (mounted) {
              setState(() => _completed = _analyses.length + (completed / total));
            }
          },
        );
        if (mounted) {
          setState(() {
            _analyses[device.id] = result;
            _completed = _analyses.length.toDouble();
          });
        }
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _skipDuplicates() {
    for (final analysis in _analyses.values) {
      for (final file in analysis.files) {
        if (file.isExact) file.isIncluded = false;
      }
    }
    setState(() => _reviewing = true);
  }

  void _transferEverything() {
    for (final analysis in _analyses.values) {
      for (final file in analysis.files) {
        file.isIncluded = true;
      }
    }
    setState(() => _reviewing = true);
  }

  void _sendBestPhotos() {
    for (final analysis in _analyses.values) {
      final recommendation = _handoffService.recommend(
        analysis.files.map((item) => item.file).toList(),
      );
      final bestPaths = recommendation.bestFiles.map((file) => file.path).toSet();
      for (final item in analysis.files) {
        item.isIncluded = !item.isExact && bestPaths.contains(item.file.path);
      }
    }
    setState(() => _reviewing = true);
  }

  void _startTransfer() {
    final filesByDevice = <String, List<SelectedFile>>{
      for (final entry in _analyses.entries) entry.key: entry.value.includedFiles,
    };
    if (_isMultiDevice) {
      context.pushReplacement(
        AppRoutes.multiDeviceTransfer,
        extra: {'files': widget.files, 'devices': widget.devices, 'filesByDevice': filesByDevice},
      );
    } else {
      final device = widget.devices.first;
      final files = filesByDevice[device.id] ?? widget.files;
      context.pushReplacement(
        AppRoutes.deviceConnection,
        extra: {'files': files, 'device': device},
      );
    }
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
          onPressed: () => context.pop(),
        ),
        title: Text('Smart Transfer Check', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
      ),
      body: SafeArea(
        child: _isAnalyzing
            ? _buildProgress()
            : _error != null
                ? _buildError()
                : _buildReview(),
      ),
    );
  }

  Widget _buildProgress() {
    final total = widget.devices.length * widget.files.length;
    final progress = total == 0 ? 0.0 : (_completed / total).clamp(0.0, 1.0).toDouble();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_outlined, size: 52, color: AppColors.secondary),
            const SizedBox(height: AppSpacing.md),
            Text('Analyzing files...', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 280,
              child: LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(AppSpacing.full)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('${(progress * 100).round()}%', style: AppTypography.telemetryData.copyWith(color: AppColors.secondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Could not check this device', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: AppSpacing.sm),
            Text('Make sure the receiver has FlowSend open in Receive Files mode.', textAlign: TextAlign.center, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: () => context.pop(), child: const Text('Back')),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildSummary(),
        const SizedBox(height: AppSpacing.md),
        if (!_reviewing) ...[
          Text('What would you like to do with these files?', style: AppTypography.labelLg.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          _ActionButton(label: 'Send Everything', icon: Icons.done_all, onPressed: _transferEverything),
          const SizedBox(height: AppSpacing.sm),
          _ActionButton(label: 'Send New Only', icon: Icons.new_releases_outlined, onPressed: _skipDuplicates),
          const SizedBox(height: AppSpacing.sm),
          _ActionButton(label: 'Send Best Photos', icon: Icons.auto_awesome, onPressed: _sendBestPhotos),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(onPressed: () => setState(() => _reviewing = true), icon: const Icon(Icons.fact_check_outlined), label: const Text('Review')),
        ] else ...[
          ..._analyses.values.expand((analysis) => analysis.files.map(_buildFileRow)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: 52, child: FilledButton.icon(onPressed: _startTransfer, icon: const Icon(Icons.send), label: Text('Start Transfer · ${_includedCount()} files'))),
        ],
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.55))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FlowSend found files you may not need to transfer.', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        Text('${widget.files.length} files · ${FileSizeFormatter.format(widget.files.fold(0, (sum, file) => sum + file.sizeBytes))}', style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.md),
        _SummaryLine(icon: Icons.fiber_new, label: 'New files', value: '$_newCount'),
        _SummaryLine(icon: Icons.check_circle_outline, label: 'Exact duplicates', value: '$_exactCount'),
        _SummaryLine(icon: Icons.warning_amber_outlined, label: 'Possible duplicates', value: '$_possibleCount'),
        _SummaryLine(icon: Icons.video_file_outlined, label: 'Large files', value: '$_largeCount'),
        Text('Potential savings: ${FileSizeFormatter.format(_duplicateBytes)}', style: AppTypography.labelMd.copyWith(color: AppColors.secondary)),
      ]),
    );
  }

  Widget _buildFileRow(DuplicateFileAnalysis item) {
    final isExact = item.isExact;
    final isPossible = item.isPossible;
    return CheckboxListTile(
      value: item.isIncluded,
      onChanged: (value) => setState(() => item.isIncluded = value ?? true),
      activeColor: AppColors.secondary,
      title: Text(item.file.name, overflow: TextOverflow.ellipsis, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
      subtitle: Text(
        '${FileSizeFormatter.format(item.file.sizeBytes)} · ${isExact ? 'Exact duplicate' : isPossible ? 'Possible duplicate${item.remoteMatches.isEmpty ? '' : ' · matches ${item.remoteMatches.first.name}'}' : item.status == DuplicateStatus.largeFile ? 'Large file' : 'New file'}',
        style: AppTypography.bodySm.copyWith(color: isExact ? AppColors.secondary : isPossible ? AppColors.primary : AppColors.onSurfaceVariant),
      ),
    );
  }

  int _includedCount() => _analyses.values.fold(0, (sum, item) => sum + item.includedFiles.length);
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(height: 52, child: FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label)));
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: Row(children: [Icon(icon, size: 18, color: AppColors.secondary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant))), Text(value, style: AppTypography.telemetryData.copyWith(color: AppColors.onSurface))]));
}
