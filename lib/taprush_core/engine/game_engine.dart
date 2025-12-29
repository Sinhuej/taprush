import 'dart:math';
import 'models.dart';
import 'gesture.dart';
import 'input_resolver.dart';

class TapRushEngine {
  final _rng = Random();
  final RunStats stats = RunStats();

  // Uses the deterministic resolver (1 gesture -> 1 target)
  final InputResolver input = InputResolver();

  LaneGeometry? _g;
  GameMode mode = GameMode.normal;

  final List<TapEntity> entities = [];

  // Epic lanes (3 down, 3 up)
  Set<int> _epicDown = {};
  Set<int> _epicUp = {};

  double _time = 0;
  double _spawnTimer = 0;
  int _id = 0;

  static const int maxStrikes = 5;
  static const int maxBonusLives = 3;

  // Prevent overlap/stacking in-lane
  static const double _minGapFrac = 0.35; // fraction of tileHeight

  void setGeometry(LaneGeometry g) => _g = g;

  void reset({required GameMode newMode}) {
    mode = newMode;
    entities.clear();
    _time = 0;
    _spawnTimer = 0;
    _id = 0;

    stats
      ..score = 0
      ..coins = 0
      ..strikes = 0
      ..totalHits = 0
      ..perfectHits = 0
      ..bombsFlicked = 0
      ..bonusLivesEarned = 0;

    if (mode == GameMode.epic) {
      final lanes = List.generate(kLaneCount, (i) => i)..shuffle(_rng);
      _epicDown = lanes.take(3).toSet();
      _epicUp = lanes.skip(3).toSet();
    } else {
      _epicDown = {};
      _epicUp = {};
    }
  }

  bool get isGameOver => stats.strikes >= maxStrikes;

  void tick(double dt) {
    final g = _g;
    if (g == null || isGameOver) return;

    _time += dt;
    _spawnTimer += dt;

    final speed = 240 + _time * 8;

    if (_spawnTimer >= 0.45) {
      _spawnTimer = 0;
      _spawn(g);
    }

    // Move entities
    for (final e in entities) {
      e.y += e.dir == FlowDir.down ? speed * dt : -speed * dt;
    }

    // Miss handling: if a normal tile is missed -> strike
    entities.removeWhere((e) {
      if (!e.isMissed(g)) return false;
      if (!e.isBomb) stats.onStrike();
      return true;
    });
  }

  void _spawn(LaneGeometry g) {
    if (mode == GameMode.epic) {
      // 3 lanes down, 3 lanes up — every spawn tick
      for (final l in _epicDown) {
        _trySpawn(g, l, FlowDir.down);
      }
      for (final l in _epicUp) {
        _trySpawn(g, l, FlowDir.up);
      }
      return;
    }

    // Normal / Reverse: single tile each spawn tick
    final dir = mode == GameMode.reverse ? FlowDir.up : FlowDir.down;
    final lane = _rng.nextInt(kLaneCount);
    _trySpawn(g, lane, dir);
  }

  bool _canSpawnAt({
    required LaneGeometry g,
    required int lane,
    required FlowDir dir,
    required double proposedY,
  }) {
    final minSep = g.tileHeight + (g.tileHeight * _minGapFrac);

    for (final e in entities) {
      if (e.lane != lane) continue;
      if (e.dir != dir) continue;
      final dy = (e.y - proposedY).abs();
      if (dy < minSep) return false;
    }
    return true;
  }

  void _trySpawn(LaneGeometry g, int lane, FlowDir dir) {
    // Keep your hard cap to avoid lane congestion,
    // but we ALSO enforce spacing so tiles never overlap.
    final count = entities.where((e) => e.lane == lane && e.dir == dir).length;
    if (count >= 2) return;

    final isBomb = _rng.nextDouble() < 0.08;

    // Spawn just off-screen, then move into view
    final spawnY = dir == FlowDir.down ? -g.tileHeight : g.height + g.tileHeight;

    // Spacing enforcement: if unsafe, skip this spawn (do NOT overlap)
    if (!_canSpawnAt(g: g, lane: lane, dir: dir, proposedY: spawnY)) return;

    entities.add(
      TapEntity(
        id: 'e_${_id++}',
        lane: lane,
        dir: dir,
        isBomb: isBomb,
        y: spawnY,
      ),
    );
  }

  InputResult onGesture(GestureSample gesture) {
    final g = _g;
    if (g == null || isGameOver) return const InputResult.miss();

    // ✅ Deterministic: resolver chooses exactly one target at most
    final res = input.resolveGesture(
      g: g,
      entities: entities,
      gesture: gesture,
    );

    if (!res.hit || res.target == null) return res;

    final target = res.target!;

    // ✅ ONE TAP = ONE TILE: remove ONLY the chosen target
    entities.removeWhere((e) => e.id == target.id);

    // Bomb handling
    if (res.bomb) {
      if (res.flicked) {
        // Flicked bomb = safe + reward
        stats.coins += 10;
        stats.bombsFlicked++;

        // Every 20 bombs flicked -> earn a bonus life (reduce strike by 1), cap at 3
        if (stats.bombsFlicked % 20 == 0 &&
            stats.bonusLivesEarned < maxBonusLives) {
          stats.bonusLivesEarned++;
          stats.strikes = max(0, stats.strikes - 1);
        }
      } else {
        // Tapped bomb = strike
        stats.onStrike();
      }
      return res;
    }

    // Tile scoring + coins (explicit, so you ALWAYS get coins per hit)
    if (res.grade == HitGrade.perfect) {
      stats.onPerfect(coinMult: 1);
      stats.coins += 1;
    } else {
      stats.onGood(coinMult: 1);
      stats.coins += 1;
    }

    return res;
  }

  // UI uses this
  int backgroundTier() {
    if (_time < 10) return 0;
    if (_time < 25) return 1;
    if (_time < 45) return 2;
    if (_time < 70) return 3;
    return 4;
  }
}
