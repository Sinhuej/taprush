#!/usr/bin/env bash
set -e

echo "🔧 Patch 01 — Input resolver (single-hit, deterministic)"

cat > lib/taprush_core/engine/input_resolver.dart <<'EOF'
import 'models.dart';
import 'gesture.dart';

class InputResult {
  final bool hit;
  final bool bomb;
  final bool flicked;
  final HitGrade? grade;
  final String? entityId;

  const InputResult({
    required this.hit,
    required this.bomb,
    required this.flicked,
    required this.grade,
    required this.entityId,
  });

  const InputResult.miss()
      : hit = false,
        bomb = false,
        flicked = false,
        grade = null,
        entityId = null;
}

class InputResolver {
  static const double _perfectWindow = 14.0;
  static const double _goodWindow = 28.0;
  static const double _flickDistSq = 1600.0; // 40px

  InputResult resolve({
    required LaneGeometry g,
    required List<TapEntity> entities,
    required GestureSample gesture,
  }) {
    final lane = g.laneOfX(gesture.startX);

    TapEntity? closest;
    double closestDy = double.infinity;

    for (final e in entities) {
      if (e.lane != lane) continue;

      if (!e.containsTap(
        g: g,
        tapX: gesture.startX,
        tapY: gesture.startY,
      )) continue;

      final dy = (e.centerY(g) - gesture.startY).abs();
      if (dy < closestDy) {
        closestDy = dy;
        closest = e;
      }
    }

    if (closest == null) {
      return const InputResult.miss();
    }

    final flicked =
        gesture.distanceSquared >= _flickDistSq &&
        closest.isBomb;

    HitGrade? grade;
    if (!closest.isBomb) {
      if (closestDy <= _perfectWindow) {
        grade = HitGrade.perfect;
      } else if (closestDy <= _goodWindow) {
        grade = HitGrade.good;
      } else {
        return const InputResult.miss();
      }
    }

    return InputResult(
      hit: true,
      bomb: closest.isBomb,
      flicked: flicked,
      grade: grade,
      entityId: closest.id,
    );
  }
}
EOF

echo "✅ Patch 01 applied"

