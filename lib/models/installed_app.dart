/// An installed app or discoverable APK file shown on the FlowSend Apps
/// screen. Distinct from [SelectedFile] until the user actually selects it.
class InstalledApp {
  const InstalledApp({
    required this.name,
    required this.packageName,
    required this.sizeBytes,
    required this.sourcePath,
    required this.isReadable,
    this.iconBytes,
  });

  final String name;
  final String packageName;
  final int sizeBytes;

  /// Filesystem path FlowSend would read from to transfer this app.
  final String sourcePath;

  /// False when Android's package-visibility/storage rules prevent FlowSend
  /// from reading the APK bytes — FlowSend never attempts to bypass this.
  final bool isReadable;

  final List<int>? iconBytes;
}
