import 'input_result.dart';
import '../debug/debug_log.dart';
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

  Set<int> _epicDown = {};
  Set<int> _epicUp = {};

  double _time = 0;
  double _spawnTimer = 0;
  int _id = 0;

  static const int maxStrikes = 5;
  static const int maxBonusLives = 3;

  void setGeometry(LaneGeometry g) => _g = g;

  bool get isGameOver => stats.strikes >= maxStrikes;

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
    }
  }

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
    if (mode == GameMode.epic) {
      for (final l in _epicDown) {
        _trySpawn(g, l, FlowDir.down);
      }
      for (final l in _epicUp) {
        _trySpawn(g, l, FlowDir.up);
      }
    } else {
      final dir = mode == GameMode.reverse ? FlowDir.up : FlowDir.down;
      final lane = _rng.nextInt(kLaneCount);
      _trySpawn(g, lane, dir);
    }
  }

  void _trySpawn(LaneGeometry g, int lane, FlowDir dir) {
    final count = entities.where((e) => e.lane == lane && e.dir == dir).length;
    if (count >= 2) return;

    final isBomb = _rng.nextDouble() < 0.08;
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



  // --------------------------------------------------
  // Gesture debounce + double-registration protection
  // --------------------------------------------------
  int _lastGestureTs = 0;
  int _lastGestureHash = 0;
  static const int _gestureDebounceMs = 40;


  int _accuracyBonus() {
    final acc = stats.accuracy;
    if (acc >= 0.98) return 2;
    if (acc >= 0.95) return 1;
    return 0;
  }

  InputResult onGesture(GestureSample gesture) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final g = _g;

    final gestureHash = gesture.toString().hashCode;

    // 🚫 DOUBLE GESTURE GUARD
    if (now - _lastGestureTs < _gestureDebounceMs &&
        gestureHash == _lastGestureHash) {
      DebugLog.log(
        'DOUBLE_GESTURE',
        'Blocked duplicate gesture (${now - _lastGestureTs}ms)',
        _time,
      );
      return const InputResult.miss();
    }

    _lastGestureTs = now;
    _lastGestureHash = gestureHash;

    DebugLog.log('GESTURE', gesture.toString(), _time);

    if (g == null || isGameOver) {
      return const InputResult.miss();
    }

    final res = input.resolve(
      g: g,
      entities: entities,
      gesture: gesture,
    );

    DebugLog.log(
      'GESTURE_RESULT',
      'hit=${res.hit} flick=${res.flicked}',
      _time,
    );

    if (!res.hit || res.entity == null) {
      return res;
    }

    final target = res.entity!;

    // 🔒 HARD ENTITY GUARD
    if (target.consumed) {
      DebugLog.log(
        'DOUBLE_SCORE',
        'Blocked entity id=${target.id}',
        _time,
      );
      return const InputResult.miss();
    }

    target.consumed = true;
    entities.remove(target);

    DebugLog.log(
      'HIT',
      'id=${target.id} bomb=${target.isBomb} flick=${res.flicked}',
      _time,
    );

    if (target.isBomb) {
      if (res.flicked) {
        stats.coins += 10;
        stats.bombsFlicked++;
      } else {
        stats.onStrike();
      }
      return res;
    }

    if (res.grade == HitGrade.perfect) {
      stats.onPerfect();
    } else {
      stats.onGood();
      final bonus = _accuracyBonus();
      if (bonus > 0) {
        stats.score += bonus;
        DebugLog.log('ACCURACY_BONUS', '+$bonus', _time);
      }
    }

    DebugLog.log('SCORE', 'score=${stats.score}', _time);
    return res;
  }
}
