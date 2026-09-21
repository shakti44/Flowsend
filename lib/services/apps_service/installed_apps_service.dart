import 'dart:io';

import 'package:flutter/services.dart';

import '../../models/installed_app.dart';

/// Bridge to the native Android installed-app inventory.
///
/// Backed by PackageManager's launcher-intent query — the same
/// package-visibility-exempt mechanism a home-screen launcher uses. FlowSend
/// never requests QUERY_ALL_PACKAGES and never reads another app's private
/// data; unreadable APKs are reported as such, not silently skipped.
class InstalledAppsService {
  const InstalledAppsService();

  static const _channel = MethodChannel('flowsend/apps');

  Future<List<InstalledApp>> getInstalledApps() async {
    if (!Platform.isAndroid) return const [];
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (result == null) return const [];
      return result.map((raw) {
        final map = (raw as Map).cast<String, dynamic>();
        return InstalledApp(
          name: map['name'] as String? ?? map['packageName'] as String,
          packageName: map['packageName'] as String,
          sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
          sourcePath: map['sourceDir'] as String,
          isReadable: map['isReadable'] as bool? ?? false,
          iconBytes: (map['iconBytes'] as List?)?.cast<int>(),
        );
      }).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } on Object {
      return const [];
    }
  }
}
