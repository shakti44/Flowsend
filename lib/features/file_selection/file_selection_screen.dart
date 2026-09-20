import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/selected_file.dart';
import '../../models/discovered_device.dart';
import '../../services/file_service/file_picker_service.dart';
import '../../services/file_service/file_service.dart';
import '../../widgets/file_item_card.dart';
import '../../routes/app_router.dart';

/// File Selection Screen — matches Stitch select_files design.
/// Filter chips, file queue cards, total size bar, Continue CTA.
class FileSelectionScreen extends StatefulWidget {
  const FileSelectionScreen({super.key, this.initialCategory, this.targetDevice});

  final FileSelectionCategory? initialCategory;
  final DiscoveredDevice? targetDevice;

  @override
  State<FileSelectionScreen> createState() => _FileSelectionScreenState();
}

class _FileSelectionScreenState extends State<FileSelectionScreen> {
  final FileService _fileService = const FilePickerService();
  final List<SelectedFile> _selectedFiles = [];
  late FileSelectionCategory _activeCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.initialCategory ?? FileSelectionCategory.photos;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialPicker();
    });
  }

  Future<void> _openInitialPicker() async {
    // Let the route finish its first frame before launching DocumentsUI.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) await _pickFiles(widget.initialCategory ?? FileSelectionCategory.files);
  }

  int get _totalBytes =>
      _selectedFiles.fold(0, (sum, f) => sum + f.sizeBytes);

  Future<void> _pickFiles(FileSelectionCategory category) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      List<SelectedFile> picked;
      switch (category) {
        case FileSelectionCategory.photos:
          picked = await _fileService.pickPhotos();
        case FileSelectionCategory.videos:
          picked = await _fileService.pickVideos();
        case FileSelectionCategory.documents:
          picked = await _fileService.pickDocuments();
        case FileSelectionCategory.apps:
          picked = await _fileService.pickApps();
        case FileSelectionCategory.files:
          picked = await _fileService.pickFiles();
        case FileSelectionCategory.folders:
          picked = await _fileService.pickDirectory();
      }
      if (!mounted) return;
      setState(() {
        _activeCategory = category;
        for (final f in picked) {
          if (!_selectedFiles.contains(f)) _selectedFiles.add(f);
        }
      });
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Files could not be opened. Try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeFile(SelectedFile file) {
    setState(() => _selectedFiles.remove(file));
  }

  void _clearAll() {
    setState(() => _selectedFiles.clear());
  }

  void _continue() {
    if (_selectedFiles.isEmpty) return;
    if (widget.targetDevice != null) {
      context.push(AppRoutes.smartTransferCheck, extra: {
        'files': _selectedFiles,
        'devices': [widget.targetDevice!],
      });
      return;
    }
    context.push(AppRoutes.chooseDevice, extra: _selectedFiles);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildTopBar(context),
            const SizedBox(height: AppSpacing.xs),
            _buildFilterChips(),
            const SizedBox(height: AppSpacing.sm),
            _buildQueueHeader(),
            const SizedBox(height: AppSpacing.sm),
            _buildFileList(),
            _buildSecurityPill(),
            _buildBottomBar(),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainer,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
              fixedSize: const Size(40, 40),
            ),
            icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.onSurface),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select files',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
                ),
                Text(
                  'Choose payload for peer beam',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (!isCompact)
            SizedBox(
              width: 88,
              child: OutlinedButton.icon(
                onPressed: () => _pickFiles(_activeCategory),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainer,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  foregroundColor: AppColors.onSurface,
                  minimumSize: const Size(88, 48),
                  maximumSize: const Size(88, 48),
                ),
                icon: const Icon(Icons.folder_open, size: 18, color: AppColors.secondary),
                label: Text('Browse', style: AppTypography.labelSm.copyWith(color: AppColors.onSurface)),
              ),
            )
          else
            IconButton(
              onPressed: () => _pickFiles(_activeCategory),
              tooltip: 'Browse files',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceContainer,
                shape: const CircleBorder(),
                fixedSize: const Size(40, 40),
              ),
              icon: const Icon(Icons.folder_open, size: 20, color: AppColors.secondary),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: FileSelectionCategory.values.map((cat) {
          final isActive = cat == _activeCategory;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => _pickFiles(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.full),
                  boxShadow: isActive
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8)]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 18,
                        color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      cat.label,
                      style: AppTypography.labelMd.copyWith(
                        color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQueueHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Text('Queue', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.full),
            ),
            child: Text(
              '${_selectedFiles.length} item${_selectedFiles.length == 1 ? '' : 's'}',
              style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
            ),
          ),
          const Spacer(),
          if (_selectedFiles.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.clear_all, size: 14),
              label: Text('Clear selection',
                  style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
            ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return const SizedBox(
        height: 320,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }
    if (_selectedFiles.isEmpty) {
      return SizedBox(height: 320, child: _buildEmptyState());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          for (final file in _selectedFiles) ...[
            FileItemCard(
              file: file,
              onRemove: () => _removeFile(file),
              statusLabel: 'Ready',
              statusColor: AppColors.secondaryContainer,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _buildAddMoreButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainer,
            ),
            child: const Icon(Icons.upload_file, size: 36, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No files selected', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.xs),
          Text('Tap a category above or browse', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _pickFiles(_activeCategory),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.outlineVariant),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Files'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return GestureDetector(
      onTap: () => _pickFiles(_activeCategory),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.base),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
              ),
              child: const Icon(Icons.add, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Add more files or drag & drop',
                style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityPill() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.base),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerLowest,
              ),
              child: const Icon(Icons.verified_user, color: AppColors.secondary, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('End-to-End Cryptography',
                      style: AppTypography.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                  Text('Direct Wi-Fi 6 beam · No cloud relays',
                      style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Ready', style: AppTypography.telemetryData.copyWith(color: AppColors.secondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.base),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _selectedFiles.isEmpty
                          ? '0 B'
                          : FileSizeFormatter.format(_totalBytes),
                      style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '/ ${_selectedFiles.length} file${_selectedFiles.length == 1 ? '' : 's'}',
                      style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                if (_selectedFiles.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text('Storage verified',
                          style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 124,
            height: 48,
            child: FilledButton.icon(
              onPressed: _selectedFiles.isEmpty ? null : _continue,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                disabledBackgroundColor: AppColors.surfaceContainerHighest,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(124, 48),
                maximumSize: const Size(124, 48),
              ),
              icon: const Text('Continue'),
              label: const Icon(Icons.arrow_forward, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

enum FileSelectionCategory {
  photos(Icons.photo_library, 'Photos'),
  videos(Icons.videocam_outlined, 'Videos'),
  documents(Icons.description_outlined, 'Documents'),
  apps(Icons.android, 'Apps / APKs'),
  files(Icons.insert_drive_file_outlined, 'Files'),
  folders(Icons.inventory_2_outlined, 'Folders');

  const FileSelectionCategory(this.icon, this.label);
  final IconData icon;
  final String label;
}
