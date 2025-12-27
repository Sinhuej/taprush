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
  InputResult resolveGesture({
    required LaneGeometry g,
    required List<TapEntity> entities,
    required GestureSample gesture,
  }) {
    final lane = g.laneOfX(gesture.startX);

    final candidates = <TapEntity>[];
    for (final e in entities) {
      if (e.lane != lane) continue;
      if (e.containsTap(
        g: g,
        tapX: gesture.startX,
        tapY: gesture.startY,
      )) {
        candidates.add(e);
      }
    }

    if (candidates.isEmpty) return const InputResult.miss();

    // closest center to finger start wins
    candidates.sort((a, b) {
      final da = (a.centerY(g) - gesture.startY).abs();
      final db = (b.centerY(g) - gesture.startY).abs();
      return da.compareTo(db);
    });

    final target = candidates.first;

    // Bomb logic
    if (target.isBomb) {
      if (gesture.isFlick) {
        return const InputResult(hit: true, bomb: true, flicked: true, grade: null);
      }
      return const InputResult(hit: true, bomb: true, flicked: false, grade: null);
    }

    // Tile logic: accuracy based on closeness to tile center
    final dy = (target.centerY(g) - gesture.startY).abs();
    final norm = dy / (g.tileHeight / 2); // 0=center, 1=edge

    // LOCKED: forgiving perfect window
    final grade = norm <= 0.55 ? HitGrade.perfect : HitGrade.good;

    return InputResult(hit: true, bomb: false, flicked: false, grade: grade);
  }
}
