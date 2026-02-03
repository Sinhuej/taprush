import 'input_result.dart';
import 'models.dart';
import 'gesture.dart';
import '../debug/debug_log.dart';

enum MissReason {
  emptySpace,
  microDrag,
  flickNoTarget,
  bombAvoided,
}

class InputResolver {
  static const double flickVelocityMin = 0.20;
  static const double flickDistanceMin = 60;

  // Micro-drag classification (tap that moved a little)
  static const double microDragDistMax = 20.0;
  static const double microDragVelMax = 0.15;

  // Horizontal forgiveness as a fraction of lane width
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

    final bool isFlick = gesture.velocity >= flickVelocityMin &&
        gesture.distance >= flickDistanceMin;

    DebugLog.log(
      'GESTURE_CLASS',
      'isFlick=$isFlick (vel>=${flickVelocityMin}, dist>=${flickDistanceMin})',
      g.height,
    );

    final double toleranceX = g.laneWidth * horizontalToleranceFactor;

    // 🔒 FINAL tuned vertical forgiveness
    final double padY = g.tileHeight * 0.45;

    TapEntity? best;
    double bestScore = double.infinity;

    for (final e in entities) {
      if (e.consumed) continue;

      final double entityCenterX =
          (e.lane * g.laneWidth) + (g.laneWidth / 2);

      final double dx = (entityCenterX - gesture.start.dx).abs();
      if (dx > toleranceX) continue;

      final double tileTop =
          e.dir == FlowDir.down ? e.y : (e.y - g.tileHeight);
      final double tileBottom = tileTop + g.tileHeight;

      final double tapY = gesture.start.dy;
      if (tapY < (tileTop - padY) || tapY > (tileBottom + padY)) continue;

      final double centerY = tileTop + g.tileHeight / 2;
      final double dy = (centerY - tapY).abs();

      DebugLog.log(
        'ENTITY',
        'id=${e.id} bomb=${e.isBomb} dx=${dx.toStringAsFixed(1)} '
        'dy=${dy.toStringAsFixed(1)}',
        g.height,
      );

      final double score = dx + (dy * 0.25);

      if (score < bestScore) {
        bestScore = score;
        best = e;
      }
    }

    // ─────────────────────────────────────────────
    // MISS CLASSIFICATION
    // ─────────────────────────────────────────────
    if (best == null) {
      final MissReason reason = isFlick
          ? MissReason.flickNoTarget
          : _isMicroDrag(gesture)
              ? MissReason.microDrag
              : MissReason.emptySpace;

      DebugLog.log(
        'MISS',
        'reason=${reason.name}',
        g.height,
      );

      return const InputResult.miss();
    }

    // Tap on bomb is intentionally ignored
    if (!isFlick && best.isBomb) {
      DebugLog.log(
        'MISS',
        'reason=${MissReason.bombAvoided.name} id=${best.id}',
        g.height,
      );
      return const InputResult.miss();
    }

    // ─────────────────────────────────────────────
    // HIT
    // ─────────────────────────────────────────────
    return InputResult.hit(
      entity: best,
      flicked: isFlick,
      grade: HitGrade.good,
    );
  }

  bool _isMicroDrag(GestureSample g) {
    return g.distance > 0 &&
        g.distance <= microDragDistMax &&
        g.velocity <= microDragVelMax;
  }
}
