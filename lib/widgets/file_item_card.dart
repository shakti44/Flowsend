import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_typography.dart';
import '../models/selected_file.dart';
import '../core/utils/file_size_formatter.dart';

/// File queue item card — matches Stitch select_files card design.
/// Shows thumbnail/icon, file name, size, type, and optional status badge.
class FileItemCard extends StatelessWidget {
  const FileItemCard({
    super.key,
    required this.file,
    this.onRemove,
    this.statusLabel,
    this.statusColor,
  });

  final SelectedFile file;
  final VoidCallback? onRemove;
  final String? statusLabel;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.base),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            // Thumbnail / Icon plinth
            _FileThumbnail(file: file),
            const SizedBox(width: AppSpacing.md),

            // Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          file.name,
                          style: AppTypography.labelLg.copyWith(
                            color: AppColors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onRemove != null)
                        GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppSpacing.full),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        FileSizeFormatter.format(file.sizeBytes),
                        style: AppTypography.telemetryData.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.outlineVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _fileTypeLabel(file),
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (statusLabel != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (statusColor ?? AppColors.secondaryContainer)
                                .withValues(alpha: 0.20),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      statusColor ?? AppColors.secondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                statusLabel!,
                                style: AppTypography.labelSm.copyWith(
                                  color: statusColor ?? AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fileTypeLabel(SelectedFile file) {
    return switch (file.category) {
      FileCategory.photo => 'Photo',
      FileCategory.video => 'Video',
      FileCategory.document => 'Document',
      FileCategory.file => file.extension.toUpperCase().isEmpty
          ? 'File'
          : '${file.extension.toUpperCase()} File',
    };
  }
}

class _FileThumbnail extends StatelessWidget {
  const _FileThumbnail({required this.file});
  final SelectedFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _iconForCategory(file.category),
            size: 28,
            color: _colorForCategory(file.category),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                file.extension.toUpperCase().isEmpty
                    ? 'FILE'
                    : file.extension.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForCategory(FileCategory c) => switch (c) {
        FileCategory.photo => Icons.image_outlined,
        FileCategory.video => Icons.videocam_outlined,
        FileCategory.document => Icons.description_outlined,
        FileCategory.file => Icons.insert_drive_file_outlined,
      };

  static Color _colorForCategory(FileCategory c) => switch (c) {
        FileCategory.photo => AppColors.secondary,
        FileCategory.video => AppColors.primary,
        FileCategory.document => AppColors.tertiary,
        FileCategory.file => AppColors.onSurfaceVariant,
      };
}
