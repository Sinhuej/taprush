import '../engine/models.dart';

class AppState {
  int coins = 0;

  bool reverseUnlocked = false;
  bool epicUnlocked = false;

  GameMode selectedMode = GameMode.normal;

  bool canPlay(GameMode m) {
    if (m == GameMode.normal) return true;
    if (m == GameMode.reverse) return reverseUnlocked;
    if (m == GameMode.epic) return epicUnlocked;
    return false;
  }

  int unlockCost(GameMode m) {
    if (m == GameMode.reverse) return 20000;
    if (m == GameMode.epic) return 50000;
    return 0;
  }

  bool tryUnlock(GameMode m) {
    final cost = unlockCost(m);
    if (cost <= 0) return true;
    if (coins < cost) return false;

    coins -= cost;
    if (m == GameMode.reverse) reverseUnlocked = true;
    if (m == GameMode.epic) epicUnlocked = true;
    return true;
  }
}

// Singleton (simple, ship-now)
final appState = AppState();
