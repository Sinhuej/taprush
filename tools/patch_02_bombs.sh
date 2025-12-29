#!/usr/bin/env bash
set -e

echo "💣 Patch 02 — Bomb flick logic & rewards"

cat > lib/taprush_core/engine/game_engine.dart <<'EOF'
import 'dart:math';
import 'models.dart';
import 'gesture.dart';
import 'input_resolver.dart';

class TapRushEngine {
  final _rng = Random();
  final RunStats stats = RunStats();
  final InputResolver input = InputResolver();

  LaneGeometry? _g;
  GameMode mode = GameMode.normal;
  final List<TapEntity> entities = [];

  double _time = 0;
  double _spawnTimer = 0;
  int _id = 0;

  static const int maxStrikes = 5;
  static const int maxBonusLives = 3;

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
  }

  bool get isGameOver => stats.strikes >= maxStrikes;

  void tick(double dt) {
    final g = _g;
    if (g == null || isGameOver) return;

    _time += dt;
    _spawnTimer += dt;

    final speed = 260 + _time * 9;

    if (_spawnTimer >= 0.42) {
      _spawnTimer = 0;
      _spawn(g);
    }

    for (final e in entities) {
      e.y += e.dir == FlowDir.down ? speed * dt : -speed * dt;
    }

    entities.removeWhere((e) {
      if (!e.isMissed(g)) return false;
      if (!e.isBomb) stats.onStrike();
      return true;
    });
  }

  void _spawn(LaneGeometry g) {
    final dir = mode == GameMode.reverse ? FlowDir.up : FlowDir.down;
    final lane = _rng.nextInt(kLaneCount);

    final isBomb = _rng.nextDouble() < 0.10;
    final y = dir == FlowDir.down ? -g.tileHeight : g.height + g.tileHeight;

    entities.add(
      TapEntity(
        id: 'e_${_id++}',
        lane: lane,
        dir: dir,
        isBomb: isBomb,
        y: y,
      ),
    );
  }

  InputResult onGesture(GestureSample gesture) {
    final g = _g;
    if (g == null || isGameOver) return const InputResult.miss();

    final res = input.resolve(
      g: g,
      entities: List.of(entities),
      gesture: gesture,
    );

    if (!res.hit || res.entityId == null) return res;

    entities.removeWhere((e) => e.id == res.entityId);

    if (res.bomb) {
      if (res.flicked) {
        stats.bombsFlicked++;
        stats.coins += 10;

        if (stats.bombsFlicked % 20 == 0 &&
            stats.bonusLivesEarned < maxBonusLives) {
          stats.bonusLivesEarned++;
          stats.strikes = max(0, stats.strikes - 1);
        }
      } else {
        stats.onStrike();
      }
      return res;
    }

    if (res.grade == HitGrade.perfect) {
      stats.onPerfect(coinMult: 1);
    } else {
      stats.onGood(coinMult: 1);
    }

    return res;
  }

  int backgroundTier() {
    if (_time < 10) return 0;
    if (_time < 25) return 1;
    if (_time < 45) return 2;
    if (_time < 70) return 3;
    return 4;
  }
}
EOF

echo "✅ Patch 02 applied"

