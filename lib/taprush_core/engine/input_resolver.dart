import 'models.dart';
import 'gesture.dart';

class InputResult {
  final bool hit;
  final bool bomb;
  final bool flicked;
  final HitGrade? grade;
  final TapEntity? entity;

  const InputResult({
    required this.hit,
    required this.bomb,
    required this.flicked,
    required this.grade,
    required this.entity,
  });

  const InputResult.miss()
      : hit = false,
        bomb = false,
        flicked = false,
        grade = null,
        entity = null;
}

class InputResolver {
  static const double _flickDistSq = 28 * 28;
  static const int _maxFlickMs = 300;

  InputResult resolve({
    required LaneGeometry g,
    required List<TapEntity> entities,
    required GestureSample gesture,
  }) {
    final lane = g.laneOfX(gesture.startX);

    TapEntity? best;
    double bestDist = double.infinity;

    for (final e in entities) {
      if (e.lane != lane) continue;
      if (!e.containsTap(
        g: g,
        tapX: gesture.startX,
        tapY: gesture.startY,
      )) continue;

      final d = (e.centerY(g) - gesture.startY).abs();
      if (d < bestDist) {
        bestDist = d;
        best = e;
      }
    }

    if (best == null) return const InputResult.miss();

    final isFlick =
        gesture.distanceSquared >= _flickDistSq &&
        gesture.durationMs <= _maxFlickMs;

    return InputResult(
      hit: true,
      bomb: best.isBomb,
      flicked: best.isBomb && isFlick,
      grade: best.isBomb ? null : HitGrade.perfect,
      entity: best,
    );
  }
}
