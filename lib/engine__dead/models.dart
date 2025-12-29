class Tile {
  final int id;
  final int lane;     // 0..laneCount-1
  double y;           // top-left Y
  final double height;

  Tile({
    required this.id,
    required this.lane,
    required this.y,
    required this.height,
  });
}

class EngineSnapshot {
  final List<Tile> tiles;
  final int score;
  final int strikes;
  final bool gameOver;

  const EngineSnapshot({
    required this.tiles,
    required this.score,
    required this.strikes,
    required this.gameOver,
  });
}
