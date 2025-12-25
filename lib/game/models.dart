import 'scroll_direction.dart';

class Tile {
  final int lane; // 0..5
  double y;
  final double height;
  final ScrollDirection dir;

  Tile({
    required this.lane,
    required this.y,
    required this.height,
    required this.dir,
  });
}

class GameSnapshot {
  final int score;
  final int strikes;
  final int stage;
  final double speed;
  final bool gameOver;
  final bool epicRetryAvailable; // prompt should show if true
  final List<Tile> tiles;

  const GameSnapshot({
    required this.score,
    required this.strikes,
    required this.stage,
    required this.speed,
    required this.gameOver,
    required this.epicRetryAvailable,
    required this.tiles,
  });
}
