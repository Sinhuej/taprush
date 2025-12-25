enum GameMode {
  classic,
  reverse,
  epic,
}

extension GameModeX on GameMode {
  String get key {
    switch (this) {
      case GameMode.classic: return 'classic';
      case GameMode.reverse: return 'reverse';
      case GameMode.epic: return 'epic';
    }
  }

  String get label {
    switch (this) {
      case GameMode.classic: return 'Classic';
      case GameMode.reverse: return 'Reverse';
      case GameMode.epic: return 'Epic';
    }
  }

  int get coinMultiplier {
    switch (this) {
      case GameMode.classic: return 1;
      case GameMode.reverse: return 2;
      case GameMode.epic: return 3;
    }
  }
}
