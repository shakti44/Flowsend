import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transfer_record.dart';

/// Persists completed transfer records locally across app restarts.
class HistoryService {
  HistoryService({SharedPreferences? preferences}) : _preferences = preferences;

  static const _storageKey = 'transfer_history';
  SharedPreferences? _preferences;

  Future<List<TransferRecord>> load() async {
    final preferences = await _getPreferences();
    final values = preferences.getStringList(_storageKey) ?? const [];
    return values
        .map((value) {
          try {
            return TransferRecord.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            );
          } on Object {
            return null;
          }
        })
        .whereType<TransferRecord>()
        .toList(growable: false);
  }

  Future<void> add(TransferRecord record) async {
    final records = await load();
    if (records.any((item) => item.sessionId == record.sessionId)) return;

    final preferences = await _getPreferences();
    final values = [
      jsonEncode(record.toJson()),
      ...records.map((item) => jsonEncode(item.toJson())),
    ];
    await preferences.setStringList(_storageKey, values);
  }

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }
}
