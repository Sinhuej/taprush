import 'models.dart';
import 'gesture.dart';

class InputResult {
  final bool hit;
  final bool bomb;
  final bool flicked;
  final HitGrade? grade;

  const InputResult({
    required this.hit,
    required this.bomb,
    required this.flicked,
    required this.grade,
  });

  const InputResult.miss()
      : hit = false,
        bomb = false,
        flicked = false,
        grade = null;
}

class InputResolver {
  InputResult resolve({
    required LaneGeometry g,
    required List<TapEntity> entities,
    required GestureSample gesture,
  }) {
    final lane = g.laneOfX(gesture.startX);

    TapEntity? target;
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
        target = e;
      }
    }

    if (target == null) return const InputResult.miss();

    // Bomb logic
    if (target.isBomb) {
      return InputResult(
        hit: true,
        bomb: true,
        flicked: gesture.isFlick,
        grade: null,
      );
    }

    // Accuracy: forgiving inner window
    final norm = bestDist / (g.tileHeight / 2);
    final grade = norm <= 0.55 ? HitGrade.perfect : HitGrade.good;

    return InputResult(
      hit: true,
      bomb: false,
      flicked: false,
      grade: grade,
    );
  }
}
