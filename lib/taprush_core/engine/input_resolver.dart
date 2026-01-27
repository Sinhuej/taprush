import 'input_result.dart';
import 'models.dart';
import 'gesture.dart';
import '../debug/debug_log.dart';

class InputResolver {
  static const double flickVelocityMin = 0.20;
  static const double flickDistanceMin = 60;

  // Horizontal forgiveness as a fraction of lane width
  // 0.4 = ±40% of lane width
  static const double horizontalToleranceFactor = 0.4;

  InputResult resolve({
    required LaneGeometry g,
    required List<TapEntity> entities,
    required GestureSample gesture,
  }) {
    DebugLog.log(
      'GESTURE_RAW',
      'dur=${gesture.durationMs}ms dist=${gesture.distance.toStringAsFixed(1)} '
      'vel=${gesture.velocity.toStringAsFixed(2)}',
      g.height,
    );

    final isFlick = gesture.velocity >= flickVelocityMin &&
        gesture.distance >= flickDistanceMin;

    DebugLog.log(
      'GESTURE_CLASS',
      'isFlick=$isFlick (vel>=${flickVelocityMin}, dist>=${flickDistanceMin})',
      g.height,
    );

    final double tolerancePx = g.laneWidth * horizontalToleranceFactor;

    TapEntity? best;
    double bestScore = double.infinity;

    for (final e in entities) {
      if (e.consumed) continue;

      final top = e.dir == FlowDir.down ? e.y : e.y - g.tileHeight;
      final centerY = top + g.tileHeight / 2;

      // Vertical proximity (existing hit window logic stays implicit)
      final dy = (centerY - gesture.start.dy).abs();

      // Horizontal proximity (entity-first)
      final dx = (e.centerX - gesture.start.dx).abs();
      if (dx > tolerancePx) continue;

      DebugLog.log(
        'ENTITY',
        'id=${e.id} bomb=${e.isBomb} dx=${dx.toStringAsFixed(1)} '
        'dy=${dy.toStringAsFixed(1)}',
        g.height,
      );

      // Weighted distance: horizontal intent matters more than vertical
      final score = dx + (dy * 0.25);

      if (score < bestScore) {
        bestScore = score;
        best = e;
      }
    }

    if (best == null) {
      DebugLog.log('MISS', 'No clear entity intent', g.height);
      return const InputResult.miss();
    }

    return InputResult.hit(
      entity: best,
      flicked: isFlick,
      grade: HitGrade.good,
    );
  }
}
