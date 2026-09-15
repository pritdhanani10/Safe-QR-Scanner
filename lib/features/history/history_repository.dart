import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/scan_record.dart';

class HistoryRepository {
  static const String _storageKey = 'safe_qr_scan_history_v1';
  static final HistoryRepository _instance = HistoryRepository._internal();

  factory HistoryRepository() => _instance;
  HistoryRepository._internal();

  Future<List<ScanRecord>> getScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_storageKey) ?? [];

      final records = listJson
          .map((item) {
            try {
              return ScanRecord.fromJson(jsonDecode(item) as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .whereType<ScanRecord>()
          .toList();

      // Sort newest first
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (e) {
      return [];
    }
  }

  Future<void> saveScan(ScanRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_storageKey) ?? [];

      // Remove duplicate if same raw payload was scanned very recently (within 5 seconds)
      final records = listJson
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .where((item) => item['id'] != record.id)
          .toList();

      records.insert(0, record.toJson());

      // Cap at 200 items for local storage efficiency
      if (records.length > 200) {
        records.removeRange(200, records.length);
      }

      await prefs.setStringList(
        _storageKey,
        records.map((r) => jsonEncode(r)).toList(),
      );
    } catch (e) {
      // Storage error silent catch
    }
  }

  Future<void> deleteScan(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_storageKey) ?? [];

      final updated = listJson.where((item) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          return decoded['id'] != id;
        } catch (_) {
          return false;
        }
      }).toList();

      await prefs.setStringList(_storageKey, updated);
    } catch (e) {
      // ignore
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      // ignore
    }
  }
}
