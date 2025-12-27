import 'dart:math';
import 'models.dart';
import 'input_resolver.dart';
import 'gesture.dart';

class EngineConfig {
  final int maxStrikes;
  final double baseSpeedPxPerSec;
  final double speedRampPerSec;
  final double spawnEverySec;
  final double bombChanceBase;
  final double bombChanceRampPerSec;

  const EngineConfig({
    this.maxStrikes = 5,
    this.baseSpeedPxPerSec = 240,
    this.speedRampPerSec = 9,
    this.spawnEverySec = 0.48,
    this.bombChanceBase = 0.06,
    this.bombChanceRampPerSec = 0.002,
  });
}

class TapRushEngine {
  final _rng = Random();
  final EngineConfig cfg;

  TapRushEngine({EngineConfig? config}) : cfg = config ?? const EngineConfig();

  GameMode mode = GameMode.normal;
  LaneGeometry? _g;

  final RunStats stats = RunStats();
  final List<TapEntity> entities = [];
  final InputResolver input = InputResolver();

  double _t = 0.0;
  double _spawnTimerDown = 0.0;
  double _spawnTimerUp = 0.0;
  int _id = 0;

  bool get isGameOver => stats.strikes >= cfg.maxStrikes;
  int get coinMult => mode == GameMode.reverse ? 2 : 1;

  void setGeometry(LaneGeometry g) => _g = g;

  void reset({required GameMode newMode}) {
    mode = newMode;
    entities.clear();

    stats.score = 0;
    stats.strikes = 0;
    stats.coins = 0;
    stats.perfectStreak = 0;
    stats.totalHits = 0;
    stats.perfectHits = 0;

    _t = 0.0;
    _spawnTimerDown = 0.0;
    _spawnTimerUp = 0.0;
  }

  double _speed() => cfg.baseSpeedPxPerSec + (_t * cfg.speedRampPerSec);

  double _bombChance() {
    final c = cfg.bombChanceBase + (_t * cfg.bombChanceRampPerSec);
    return c.clamp(0.06, 0.35);
  }

  void tick(double dt) {
    final g = _g;
    if (g == null || isGameOver) return;

    _t += dt;

    final speed = _speed();
    final bombChance = _bombChance();

    _spawnTimerDown += dt;
    _spawnTimerUp += dt;

    final wantDown = (mode == GameMode.normal) || (mode == GameMode.epic);
    final wantUpBase = (mode == GameMode.reverse) || (mode == GameMode.epic);

    // Epic staging
    bool wantUp = wantUpBase;
    double upSpawnEvery = cfg.spawnEverySec;

    if (mode == GameMode.epic) {
      if (_t < 8.0) {
        wantUp = false;
      } else if (_t < 20.0) {
        wantUp = true;
        upSpawnEvery = cfg.spawnEverySec * 2.0; // half rate
      } else {
        wantUp = true;
        upSpawnEvery = cfg.spawnEverySec; // full
      }
    }

    if (wantDown) {
      while (_spawnTimerDown >= cfg.spawnEverySec) {
        _spawnTimerDown -= cfg.spawnEverySec;
        _spawnOne(g, FlowDir.down, bombChance);
      }
    }

    if (wantUp) {
      while (_spawnTimerUp >= upSpawnEvery) {
        _spawnTimerUp -= upSpawnEvery;
        _spawnOne(g, FlowDir.up, bombChance);
      }
    }

    for (final e in entities) {
      if (e.dir == FlowDir.down) {
        e.y += speed * dt;
      } else {
        e.y -= speed * dt;
      }
    }

    // Misses cause strikes for tiles only
    entities.removeWhere((e) {
      final missed = e.isMissed(g);
      if (missed && !e.isBomb) {
        stats.onStrike();
      }
      return missed;
    });
  }

  void _spawnOne(LaneGeometry g, FlowDir dir, double bombChance) {
    final canBomb = entities.isNotEmpty || _t > 3.0;
    final isBomb = canBomb && (_rng.nextDouble() < bombChance);

    final lane = _rng.nextInt(kLaneCount);
    final startY = dir == FlowDir.down ? -g.tileHeight : g.height + g.tileHeight;

    entities.add(
      TapEntity(
        id: 'e_${_id++}',
        lane: lane,
        dir: dir,
        isBomb: isBomb,
        y: startY,
      ),
    );
  }

  InputResult onGesture(GestureSample gesture) {
    final g = _g;
    if (g == null || isGameOver) return const InputResult.miss();

    final res = input.resolveGesture(g: g, entities: entities, gesture: gesture);
    if (!res.hit) return res;

    // Remove best match in that lane at start point
    final lane = g.laneOfX(gesture.startX);
    TapEntity? target;
    for (final e in entities) {
      if (e.lane != lane) continue;
      if (e.containsTap(g: g, tapX: gesture.startX, tapY: gesture.startY)) {
        target = e;
        break;
      }
    }
    if (target != null) entities.remove(target);

    if (res.bomb && res.flicked) {
      // Safe removal
      return res;
    }
    if (res.bomb) {
      stats.onStrike();
      return res;
    }

    if (res.grade == HitGrade.perfect) {
      stats.onPerfect(coinMult: coinMult);
    } else {
      stats.onGood(coinMult: coinMult);
    }
    return res;
  }

  int backgroundTier() {
    if (_t < 10) return 0;
    if (_t < 25) return 1;
    if (_t < 45) return 2;
    if (_t < 70) return 3;
    return 4;
  }
}
