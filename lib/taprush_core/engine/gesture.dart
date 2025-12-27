class GestureSample {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final int durationMs;

  const GestureSample({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.durationMs,
  });

  double get dx => endX - startX;
  double get dy => endY - startY;

  double get distance =>
      (dx * dx + dy * dy).sqrt();

  double get velocity =>
      durationMs <= 0 ? 0 : distance / durationMs;

  bool get isFlick =>
      distance >= 48 &&
      durationMs <= 120 &&
      velocity >= 0.6;
}

extension _Sqrt on double {
  double sqrt() {
    var r = this;
    for (int i = 0; i < 6; i++) {
      r = 0.5 * (r + this / r);
    }
    return r;
  }
}
