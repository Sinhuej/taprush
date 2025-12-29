import 'models.dart';
import 'lane_geometry.dart';

class SpawnRules {
  final double minGapFrac; // fraction of tileHeight

  const SpawnRules({this.minGapFrac = 0.35});

  // Returns true if proposed spawnY is safe in this lane.
  bool canSpawnInLane({
    required LaneGeometry g,
    required List<TapEntity> entities,
    required int lane,
    required double proposedY,
  }) {
    final minGap = g.tileHeight * minGapFrac;

    // Find nearest entity in same lane by Y distance.
    double nearest = double.infinity;
    for (final e in entities) {
      if (e.lane != lane) continue;
      final dy = (e.y - proposedY).abs();
      if (dy < nearest) nearest = dy;
    }

    // If no entities in lane, OK.
    if (nearest == double.infinity) return true;

    // Require at least tileHeight + minGap separation.
    return nearest >= (g.tileHeight + minGap);
  }
}
