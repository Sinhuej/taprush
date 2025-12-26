class GameConfig {
  final int laneCount;
  final int maxStrikes;

  // Difficulty curve
  final double baseSpeed;      // px/sec
  final double rampPerScore;   // px/sec per score

  // Tap forgiveness
  final double tapForgivenessPx;

  // UI feedback timing
  final int feedbackMs;

  const GameConfig({
    this.laneCount = 6,
    this.maxStrikes = 5,

    // Slower, more playable start
    this.baseSpeed = 420,
    this.rampPerScore = 10,

    // Reasonable tap forgiveness (Phase B tuned)
    this.tapForgivenessPx = 140,

    // Subtle modern feedback
    this.feedbackMs = 110,
  });
}
