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
  double spawnEverySec = 0.55; // later can tighten

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

    // move tiles
    for (final t in _tiles) {
      t.y += speedPxPerSec * dt;
    }

    // remove tiles that fell past bottom (strike)
    _tiles.removeWhere((t) {
      final gone = t.y > screenH + 40;
      if (gone) {
        strikes += 1;
        if (strikes >= maxStrikes) gameOver = true;
      }
      return gone;
    });

    // spawn logic
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

  bool handleLaneTap({
    required int lane,
    required double hitTop,
    required double hitBottom,
    required double leniencyPx,
  }) {
    if (gameOver) return false;

    // choose the tile in that lane closest to the hit zone
    Tile? best;
    double bestDist = 1e18;

    for (final t in _tiles) {
      if (t.lane != lane) continue;

      final tileTop = t.y;
      final tileBottom = t.y + t.height;

      // overlap check with leniency
      final overlaps = (tileBottom >= (hitTop - leniencyPx)) &&
          (tileTop <= (hitBottom + leniencyPx));

      if (!overlaps) continue;

      // distance to center of hit zone
      final tileCenter = (tileTop + tileBottom) / 2.0;
      final zoneCenter = (hitTop + hitBottom) / 2.0;
      final dist = (tileCenter - zoneCenter).abs();

      if (dist < bestDist) {
        bestDist = dist;
        best = t;
      }
    }

    if (best != null) {
      _tiles.remove(best);
      score += 1;
      return true;
    }

    // miss -> strike
    strikes += 1;
    if (strikes >= maxStrikes) gameOver = true;
    return false;
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
