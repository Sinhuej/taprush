import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundStore {
  static const _kKeyPaths = 'taprush.bg.paths';

  Future<List<String>> loadPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKeyPaths);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> savePaths(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKeyPaths, jsonEncode(paths));
  }
}
