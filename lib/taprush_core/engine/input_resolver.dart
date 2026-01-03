import 'models.dart';
import 'gesture.dart';

class InputResult {
  final bool hit;
  final bool bomb;
  final bool flicked;
  final HitGrade grade;
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
        grade = HitGrade.miss,
        entity = null;
}

class InputResolver {
  InputResult resolve({
    required LaneGeometry g,
    required List<TapEntity> entities,
    required GestureSample gesture,
  }) {
    final lane = g.laneOfX(gesture.start.dx);

    for (final e in entities) {
      if (e.lane != lane) continue;

      if (!e.containsTap(g, gesture.start.dx, gesture.start.dy)) {
        continue;
      }

      final dy = (g.centerY(e) - gesture.start.dy).abs();
      final flicked = gesture.classify() == GestureType.flick;

      return InputResult(
        hit: true,
        bomb: e.isBomb,
        flicked: flicked,
        grade: dy < 20 ? HitGrade.perfect : HitGrade.good,
        entity: e,
      );
    }

    return const InputResult.miss();
  }
}
