import 'dart:math';
import 'models.dart';

class TileEngine {
  final int laneCount;
  final int maxStrikes;

  int _nextId = 1;
  final Random _rng = Random();

  final List<Tile> _tiles = [];

  int score = 0;
  int strikes = 0;
  bool gameOver = false;

  // spawn tuning
  double _spawnTimer = 0;
  double spawnEverySec = 0.58;

  // tile tuning
  double tileHeight = 140;

  TileEngine({
    required this.laneCount,
    required this.maxStrikes,
  });

  void reset() {
    _nextId = 1;
    _tiles.clear();
    score = 0;
    strikes = 0;
    gameOver = false;
    _spawnTimer = 0;
  }

  List<Tile> get tiles => _tiles;

  void tick({
    required double dt,
    required double screenH,
    required double speedPxPerSec,
  }) {
    if (gameOver) return;

    for (final t in _tiles) {
      t.y += speedPxPerSec * dt;
    }

    // tile exits bottom => strike
    _tiles.removeWhere((t) {
      final gone = t.y > screenH + 40;
      if (gone) _strike();
      return gone;
    });

    _spawnTimer += dt;
    if (_spawnTimer >= spawnEverySec) {
      _spawnTimer = 0;
      _spawnOne();
    }
  }

  void _spawnOne() {
    final lane = _rng.nextInt(laneCount);
    _tiles.add(Tile(
      id: _nextId++,
      lane: lane,
      y: -tileHeight - _rng.nextInt(120).toDouble(),
      height: tileHeight,
    ));
  }

  void _strike() {
    strikes += 1;
    if (strikes >= maxStrikes) gameOver = true;
  }

  /// Tap-anywhere behavior:
  /// - Lane is chosen by UI (based on tap X)
  /// - We select the tile in that lane whose CENTER is closest to tapY
  /// - We only allow a hit if it's within [maxDistancePx] of tapY
  /// - Otherwise it's a miss (strike)
  bool handleLaneTapAnywhere({
    required int lane,
    required double tapY,
    required double maxDistancePx,
  }) {
    if (gameOver) return false;

    Tile? best;
    double bestDist = 1e18;

    for (final t in _tiles) {
      if (t.lane != lane) continue;

      final centerY = t.y + (t.height / 2.0);
      final dist = (centerY - tapY).abs();

      if (dist < bestDist) {
        bestDist = dist;
        best = t;
      }
    }

    // A: miss if not reasonably close
    if (best == null || bestDist > maxDistancePx) {
      _strike();
      return false;
    }

    _tiles.remove(best);
    score += 1;
    return true;
  }

  EngineSnapshot snapshot() {
    return EngineSnapshot(
      tiles: List.unmodifiable(_tiles),
      score: score,
      strikes: strikes,
      gameOver: gameOver,
    );
  }
}
