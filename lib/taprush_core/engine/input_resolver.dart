import 'dart:math';

import 'models.dart';
import 'gesture.dart';

class InputResult {
  final bool hit;
  final bool bomb;
  final bool flicked;
  final HitGrade? grade;
  final TapEntity? target;

  const InputResult({
    required this.hit,
    required this.bomb,
    required this.flicked,
    required this.grade,
    required this.target,
  });

  const InputResult.miss()
      : hit = false,
        bomb = false,
        flicked = false,
        grade = null,
        target = null;
}

class InputResolver {
  // Tuning knobs (safe defaults)
  final double hitWindowGoodFrac;     // fraction of tileHeight
  final double hitWindowPerfectFrac;  // fraction of tileHeight
  final double flickMinDistPx;

  const InputResolver({
    this.hitWindowGoodFrac = 0.45,
    this.hitWindowPerfectFrac = 0.20,
    this.flickMinDistPx = 26,
  });

  InputResult resolveGesture({
    required LaneGeometry g,
    required List<TapEntity> entities,
    required GestureSample gesture,
  }) {
    final lane = g.laneOfX(gesture.startX);

    // Only consider entities in this lane.
    final laneEntities = <TapEntity>[];
    for (final e in entities) {
      if (e.lane == lane) laneEntities.add(e);
    }
    if (laneEntities.isEmpty) return const InputResult.miss();

    // Determine which entity is the "best" target:
    // pick the entity whose centerY is closest to the tapY
    // but only if within a reasonable hit window.
    TapEntity? best;
    double bestDist = double.infinity;

    for (final e in laneEntities) {
      final cy = e.centerY(g);
      final d = (cy - gesture.startY).abs();
      if (d < bestDist) {
        best = e;
        bestDist = d;
      }
    }

    if (best == null) return const InputResult.miss();

    // Gate: require tap within hit window to count.
    final tileH = g.tileHeight;
    final goodWindow = tileH * hitWindowGoodFrac;
    if (bestDist > goodWindow) return const InputResult.miss();

    // Grade by distance to center (spatial accuracy)
    final perfectWindow = tileH * hitWindowPerfectFrac;
    final grade = bestDist <= perfectWindow ? HitGrade.perfect : HitGrade.good;

    // Flick detection (for bombs)
    final dx = gesture.endX - gesture.startX;
    final dy = gesture.endY - gesture.startY;
    final flickDist = sqrt(dx * dx + dy * dy);
    final flicked = flickDist >= flickMinDistPx;

    return InputResult(
      hit: true,
      bomb: best.isBomb,
      flicked: flicked,
      grade: grade,
      target: best,
    );
  }
}
