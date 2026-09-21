import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/discovered_device.dart';
import '../../models/installed_app.dart';
import '../../models/selected_file.dart';
import '../../services/apps_service/installed_apps_service.dart';
import '../../services/file_service/file_picker_service.dart';
import '../../services/file_service/file_service.dart';
import '../../routes/app_router.dart';

enum _AppsTab { installed, apkFiles }

/// FlowSend Apps screen — replaces the old "open the system file manager"
/// shortcut with a proper in-app inventory of installed apps and APK files.
class FlowSendAppsScreen extends StatefulWidget {
  const FlowSendAppsScreen({super.key, this.targetDevice});

  final DiscoveredDevice? targetDevice;

  @override
  State<FlowSendAppsScreen> createState() => _FlowSendAppsScreenState();
}

class _FlowSendAppsScreenState extends State<FlowSendAppsScreen> {
  static const _uuid = Uuid();
  static const _installedApps = InstalledAppsService();
  final FileService _fileService = const FilePickerService();

  _AppsTab _tab = _AppsTab.installed;
  bool _isLoading = true;
  String _query = '';
  List<InstalledApp> _apps = const [];
  final List<SelectedFile> _apkFiles = [];
  final Set<String> _selectedInstalledPackages = {};
  final Set<String> _selectedApkPaths = {};

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    setState(() => _isLoading = true);
    final apps = await _installedApps.getInstalledApps();
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _isLoading = false;
    });
  }

  Future<void> _browseForApkFiles() async {
    setState(() => _isLoading = true);
    try {
      final picked = await _fileService.pickApps();
      if (!mounted) return;
      setState(() {
        for (final file in picked) {
          if (!_apkFiles.contains(file)) _apkFiles.add(file);
          _selectedApkPaths.add(file.path);
        }
      });
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('APK files could not be opened. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<InstalledApp> get _filteredApps {
    if (_query.trim().isEmpty) return _apps;
    final query = _query.trim().toLowerCase();
    return _apps.where((app) => app.name.toLowerCase().contains(query)).toList();
  }

  int get _selectedCount => _selectedInstalledPackages.length + _selectedApkPaths.length;

  int get _selectedBytes {
    var total = 0;
    for (final app in _apps) {
      if (_selectedInstalledPackages.contains(app.packageName)) total += app.sizeBytes;
    }
    for (final file in _apkFiles) {
      if (_selectedApkPaths.contains(file.path)) total += file.sizeBytes;
    }
    return total;
  }

  void _toggleInstalled(InstalledApp app) {
    if (!app.isReadable) return;
    setState(() {
      if (_selectedInstalledPackages.contains(app.packageName)) {
        _selectedInstalledPackages.remove(app.packageName);
      } else {
        _selectedInstalledPackages.add(app.packageName);
      }
    });
  }

  void _toggleApkFile(SelectedFile file) {
    setState(() {
      if (_selectedApkPaths.contains(file.path)) {
        _selectedApkPaths.remove(file.path);
      } else {
        _selectedApkPaths.add(file.path);
      }
    });
  }

  void _send() {
    if (_selectedCount == 0) return;

    final files = <SelectedFile>[];
    for (final app in _apps) {
      if (!_selectedInstalledPackages.contains(app.packageName)) continue;
      files.add(SelectedFile(
        id: _uuid.v4(),
        name: '${app.name}.apk',
        path: app.sourcePath,
        sizeBytes: app.sizeBytes,
        mimeType: 'application/vnd.android.package-archive',
        lastModified: File(app.sourcePath).existsSync()
            ? File(app.sourcePath).lastModifiedSync()
            : DateTime.now(),
      ));
    }
    for (final file in _apkFiles) {
      if (_selectedApkPaths.contains(file.path)) files.add(file);
    }
    if (files.isEmpty) return;

    if (widget.targetDevice != null) {
      context.push(AppRoutes.smartTransferCheck, extra: {
        'files': files,
        'devices': [widget.targetDevice!],
      });
      return;
    }
    context.push(AppRoutes.chooseDevice, extra: files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: AppSpacing.xs),
            _buildSearchField(),
            const SizedBox(height: AppSpacing.sm),
            _buildTabs(),
            Expanded(child: _buildBody()),
            if (_selectedCount > 0) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainer,
              shape: const CircleBorder(),
              fixedSize: const Size(40, 40),
            ),
            icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.onSurface),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Apps', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
          const Spacer(),
          if (_tab == _AppsTab.installed)
            IconButton(
              onPressed: _loadInstalledApps,
              tooltip: 'Refresh',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceContainer,
                shape: const CircleBorder(),
                fixedSize: const Size(40, 40),
              ),
              icon: const Icon(Icons.refresh, size: 20, color: AppColors.secondary),
            )
          else
            IconButton(
              onPressed: _browseForApkFiles,
              tooltip: 'Browse for APK files',
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

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TextField(
        onChanged: (value) => setState(() => _query = value),
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: 'Search apps',
          hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
          filled: true,
          fillColor: AppColors.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.full),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          Expanded(child: _TabButton(label: 'Installed Apps', isActive: _tab == _AppsTab.installed, onTap: () => setState(() => _tab = _AppsTab.installed))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _TabButton(label: 'APK Files', isActive: _tab == _AppsTab.apkFiles, onTap: () => setState(() => _tab = _AppsTab.apkFiles))),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 2));
    }
    return _tab == _AppsTab.installed ? _buildInstalledList() : _buildApkFilesList();
  }

  Widget _buildInstalledList() {
    final apps = _filteredApps;
    if (apps.isEmpty) {
      return Center(
        child: Text('No shareable apps found', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return _InstalledAppTile(
          app: app,
          selected: _selectedInstalledPackages.contains(app.packageName),
          onTap: () => _toggleInstalled(app),
        );
      },
    );
  }

  Widget _buildApkFilesList() {
    if (_apkFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_zip_outlined, size: 48, color: AppColors.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              Text('No APK files added yet', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _browseForApkFiles,
                icon: const Icon(Icons.folder_open),
                label: const Text('Browse for APK files'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      itemCount: _apkFiles.length,
      itemBuilder: (context, index) {
        final file = _apkFiles[index];
        return _ApkFileTile(
          file: file,
          selected: _selectedApkPaths.contains(file.path),
          onTap: () => _toggleApkFile(file),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$_selectedCount app${_selectedCount == 1 ? '' : 's'} selected · ${FileSizeFormatter.format(_selectedBytes)}',
              style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
            ),
          ),
          SizedBox(
            width: 120,
            height: 48,
            child: FilledButton(
              onPressed: _send,
              style: FilledButton.styleFrom(shape: const StadiumBorder()),
              child: const Text('SEND'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.full),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelMd.copyWith(color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _InstalledAppTile extends StatelessWidget {
  const _InstalledAppTile({required this.app, required this.selected, required this.onTap});
  final InstalledApp app;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: app.isReadable ? 1 : 0.5,
      child: GestureDetector(
        onTap: app.isReadable ? onTap : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                child: app.iconBytes != null
                    ? Image.memory(Uint8List.fromList(app.iconBytes!), width: 44, height: 44, fit: BoxFit.cover)
                    : Container(
                        width: 44,
                        height: 44,
                        color: AppColors.surfaceContainerHighest,
                        child: const Icon(Icons.android, color: AppColors.secondary),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface), overflow: TextOverflow.ellipsis),
                    Text(
                      app.isReadable ? FileSizeFormatter.format(app.sizeBytes) : 'Not shareable on this device',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: app.isReadable ? (_) => onTap() : null,
                activeColor: AppColors.secondary,
                checkColor: AppColors.onSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApkFileTile extends StatelessWidget {
  const _ApkFileTile({required this.file, required this.selected, required this.onTap});
  final SelectedFile file;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppSpacing.sm)),
              child: const Icon(Icons.android, color: AppColors.secondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.name, style: AppTypography.labelLg.copyWith(color: AppColors.onSurface), overflow: TextOverflow.ellipsis),
                  Text(FileSizeFormatter.format(file.sizeBytes), style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.secondary,
              checkColor: AppColors.onSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
