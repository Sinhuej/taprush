import 'dart:math';
import '../modes/game_mode.dart';
import 'models.dart';
import 'progression.dart';
import 'scroll_direction.dart';

class TileEngine {
  final int laneCount;
  final Random _rng = Random();

  final double tileHeight;
  final double spawnGapMin;
  final double spawnGapMax;

  // Tap zones are computed by UI each frame
  // Classic: uses bottom zone
  // Reverse: uses top zone
  // Epic: uses BOTH
  double tapZoneTopA = 0;      // top zone start
  double tapZoneBottomA = 0;   // top zone end
  double tapZoneTopB = 0;      // bottom zone start
  double tapZoneBottomB = 0;   // bottom zone end

  final Progression progression;

  // State
  GameMode mode = GameMode.classic;

  int score = 0;
  int strikes = 0;        // classic+reverse: 0..5, epic: unused (kept 0)
  bool gameOver = false;

  bool epicRetryUsed = false; // one retry per run
  bool epicRetryPrompt = false;

  int stage = 0;
  double speed;
  int _hitsThisStage = 0;

  final List<Tile> _tiles = [];
  final List<double> _nextSpawnCountdown;

  TileEngine({
    required this.laneCount,
    required this.tileHeight,
    required this.spawnGapMin,
    required this.spawnGapMax,
    required this.speed,
    required this.progression,
  }) : _nextSpawnCountdown = List<double>.filled(laneCount, 0) {
    reset(GameMode.classic);
  }

  void reset(GameMode newMode) {
    mode = newMode;
    score = 0;
    strikes = 0;
    gameOver = false;
    stage = 0;
    _hitsThisStage = 0;
    _tiles.clear();

    epicRetryUsed = false;
    epicRetryPrompt = false;

    for (int i = 0; i < laneCount; i++) {
      _nextSpawnCountdown[i] = _rng.nextDouble() * 0.8; // seconds
    }
  }

  List<Tile> get tiles => List.unmodifiable(_tiles);

  GameSnapshot snapshot() => GameSnapshot(
    score: score,
    strikes: strikes,
    stage: stage,
    speed: speed,
    gameOver: gameOver,
    epicRetryAvailable: (mode == GameMode.epic && epicRetryPrompt && !epicRetryUsed),
    tiles: tiles,
  );

  // Anywhere tap: choose best hittable tile depending on mode
  int pickBestLane() {
    Tile? bestTile;
    for (final t in _tiles) {
      if (_isHittable(t)) {
        if (bestTile == null || _priorityY(t) > _priorityY(bestTile!)) {
          bestTile = t;
        }
      }
    }
    return bestTile?.lane ?? -1;
  }

  double _priorityY(Tile t) {
    // For down tiles, closer to bottom is higher y.
    // For up tiles, closer to top is lower y, so invert.
    if (t.dir == ScrollDirection.down) return t.y;
    return -t.y;
  }

  void tick(double dt, double screenHeight) {
    if (gameOver) return;

    _spawnIfNeeded(dt, screenHeight);

    // move
    for (final t in _tiles) {
      if (t.dir == ScrollDirection.down) {
        t.y += speed * dt;
      } else {
        t.y -= speed * dt;
      }
    }

    // misses / escapes
    final List<Tile> toRemove = [];
    for (final t in _tiles) {
      if (mode == GameMode.epic) {
        // Epic: any escape = loss prompt
        if (t.dir == ScrollDirection.down) {
          if (t.y > screenHeight) {
            toRemove.add(t);
            _epicLose();
          }
        } else {
          if (t.y + t.height < 0) {
            toRemove.add(t);
            _epicLose();
          }
        }
      } else {
        // Classic/Reverse: miss if passes the active tap zone
        if (mode == GameMode.classic && t.dir == ScrollDirection.down) {
          if (t.y > tapZoneBottomB) { toRemove.add(t); _strike(); }
        } else if (mode == GameMode.reverse && t.dir == ScrollDirection.up) {
          if (t.y + t.height < tapZoneTopA) { toRemove.add(t); _strike(); }
        } else {
          // safety: remove stray tiles if any
          if (t.y > screenHeight + 500 || t.y < -500) toRemove.add(t);
        }
      }
    }
    _tiles.removeWhere((t) => toRemove.contains(t));
  }

  void handleLaneTap(int lane) {
    if (gameOver) return;

    if (lane < 0 || lane >= laneCount) {
      if (mode != GameMode.epic) _strike();
      return;
    }

    // find a tile in lane that is hittable; in epic there may be either direction
    Tile? candidate;
    for (final t in _tiles) {
      if (t.lane == lane && _isHittable(t)) {
        // choose the “best” hittable in that lane
        if (candidate == null || _priorityY(t) > _priorityY(candidate!)) candidate = t;
      }
    }

    if (candidate == null) {
      if (mode != GameMode.epic) _strike();
      return;
    }

    // HIT
    score++;
    _hitsThisStage++;
    _tiles.remove(candidate);

    if (_hitsThisStage >= progression.hitsPerStage) {
      _hitsThisStage = 0;
      stage++;
      speed = progression.nextSpeed(speed, stage);
    }
  }

  bool _isHittable(Tile t) {
    // Zone A = top; Zone B = bottom
    if (mode == GameMode.classic) {
      // only bottom zone matters; tiles go down
      final tileBottom = t.y + t.height;
      return tileBottom >= tapZoneTopB && t.y <= tapZoneBottomB;
    }

    if (mode == GameMode.reverse) {
      // only top zone matters; tiles go up
      final tileBottom = t.y + t.height;
      return tileBottom >= tapZoneTopA && t.y <= tapZoneBottomA;
    }

    // Epic: both zones active depending on tile direction
    if (t.dir == ScrollDirection.down) {
      final tileBottom = t.y + t.height;
      return tileBottom >= tapZoneTopB && t.y <= tapZoneBottomB;
    } else {
      final tileBottom = t.y + t.height;
      return tileBottom >= tapZoneTopA && t.y <= tapZoneBottomA;
    }
  }

  void _strike() {
    strikes++;
    if (strikes >= 5) {
      gameOver = true;
    }
  }

  void _epicLose() {
    // Epic: prompt retry (once). Do not consume retry automatically.
    gameOver = true;
    epicRetryPrompt = true;
  }

  // Called by UI only when reward ad is earned and retry is allowed
  void epicRetryContinue(double screenHeight) {
    if (mode != GameMode.epic) return;
    if (epicRetryUsed) return;

    epicRetryUsed = true;
    epicRetryPrompt = false;
    gameOver = false;

    // Clear board and re-seed spawns safely (no free points)
    _tiles.clear();
    for (int i = 0; i < laneCount; i++) {
      _nextSpawnCountdown[i] = 0.25 + _rng.nextDouble() * 0.6;
    }
  }

  void _spawnIfNeeded(double dt, double screenHeight) {
    final lanesWithTile = _tiles.map((t) => t.lane).toSet();

    for (int lane = 0; lane < laneCount; lane++) {
      if (lanesWithTile.contains(lane)) continue;

      _nextSpawnCountdown[lane] -= dt;
      if (_nextSpawnCountdown[lane] > 0) continue;

      if (mode == GameMode.classic) {
        _tiles.add(Tile(
          lane: lane,
          dir: ScrollDirection.down,
          y: -tileHeight - _rng.nextInt(240).toDouble(),
          height: tileHeight,
        ));
      } else if (mode == GameMode.reverse) {
        _tiles.add(Tile(
          lane: lane,
          dir: ScrollDirection.up,
          y: screenHeight + tileHeight + _rng.nextInt(240).toDouble(),
          height: tileHeight,
        ));
      } else {
        // Epic: random direction per spawn
        final dir = _rng.nextBool() ? ScrollDirection.down : ScrollDirection.up;
        _tiles.add(Tile(
          lane: lane,
          dir: dir,
          y: dir == ScrollDirection.down
              ? (-tileHeight - _rng.nextInt(240).toDouble())
              : (screenHeight + tileHeight + _rng.nextInt(240).toDouble()),
          height: tileHeight,
        ));
      }

      final gap = spawnGapMin + _rng.nextDouble() * (spawnGapMax - spawnGapMin);
      _nextSpawnCountdown[lane] = (gap / speed).clamp(0.12, 1.1);
    }
  }
}
