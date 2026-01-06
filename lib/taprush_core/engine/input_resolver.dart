import 'models.dart';
import 'gesture.dart';
import '../debug/debug_log.dart';

class InputResolver {
  static const double flickVelocityMin = 0.20;
  static const double flickDistanceMin = 60;

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

    final lane =
        (gesture.start.dx / g.laneWidth).floor().clamp(0, kLaneCount - 1);

    TapEntity? best;
    double bestDy = double.infinity;

    for (final e in entities) {
      if (e.lane != lane || e.consumed) continue;

      final top = e.dir == FlowDir.down ? e.y : e.y - g.tileHeight;
      final centerY = top + g.tileHeight / 2;
      final dy = (centerY - gesture.start.dy).abs();

      DebugLog.log(
        'ENTITY',
        'id=${e.id} bomb=${e.isBomb} dy=${dy.toStringAsFixed(1)}',
        g.height,
      );

      if (dy < bestDy) {
        bestDy = dy;
        best = e;
      }
    }

    if (best == null) {
      DebugLog.log('MISS', 'No entity in lane $lane', g.height);
      return const InputResult.miss();
    }

    return InputResult.hit(
      entity: best,
      flicked: isFlick,
      grade: HitGrade.good,
    );
  }
}
