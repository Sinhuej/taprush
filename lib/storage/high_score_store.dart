import 'package:shared_preferences/shared_preferences.dart';
import '../modes/game_mode.dart';

class HighScoreStore {
  String _key(GameMode mode) => 'taprush.highscore.${mode.key}';

  Future<int> load(GameMode mode) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_key(mode)) ?? 0;
  }

  Future<int> saveIfHigher(GameMode mode, int score) async {
    final p = await SharedPreferences.getInstance();
    final key = _key(mode);
    final current = p.getInt(key) ?? 0;
    if (score > current) {
      await p.setInt(key, score);
      return score;
    }
    return current;
  }
}
