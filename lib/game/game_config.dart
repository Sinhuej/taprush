class GameConfig {
  final int laneCount;
  final int maxStrikes;

  // starting difficulty (Phase C will refine)
  final double baseSpeed;      // px/sec
  final double rampPerScore;   // px/sec per score

  // hit tuning (Phase B will refine)
  final double hitZoneTopPct;    // of screen height
  final double hitZoneBottomPct; // of screen height
  final double hitLeniencyPx;    // forgiveness in pixels

  const GameConfig({
    this.laneCount = 6,
    this.maxStrikes = 5,
    this.baseSpeed = 520,         // slower start (playable)
    this.rampPerScore = 14,       // gentle ramp for now
    this.hitZoneTopPct = 0.78,
    this.hitZoneBottomPct = 0.90,
    this.hitLeniencyPx = 26,
  });
}
