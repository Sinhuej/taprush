class Progression {
  final int hitsPerStage;
  final double speedMultiplier;
  final double maxSpeed;

  const Progression({
    required this.hitsPerStage,
    required this.speedMultiplier,
    required this.maxSpeed,
  });

  double nextSpeed(double current, int newStage) {
    var s = current * speedMultiplier;
    if (newStage > 0 && newStage % 3 == 0) s *= 2.0; // “spice” moment
    if (s > maxSpeed) s = maxSpeed;
    return s;
  }
}
