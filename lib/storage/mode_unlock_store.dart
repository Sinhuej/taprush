import 'package:shared_preferences/shared_preferences.dart';
import '../modes/game_mode.dart';

class ModeUnlockStore {
  String _key(GameMode mode) => 'taprush.mode.unlocked.${mode.key}';

  Future<bool> isUnlocked(GameMode mode) async {
    if (mode == GameMode.classic) return true;
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key(mode)) ?? false;
  }

  Future<void> unlock(GameMode mode) async {
    if (mode == GameMode.classic) return;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(mode), true);
  }
}
