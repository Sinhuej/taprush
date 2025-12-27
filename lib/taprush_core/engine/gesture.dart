import 'dart:math';

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

  double get distance => sqrt(dx * dx + dy * dy);

  double get velocity => durationMs <= 0 ? 0 : distance / durationMs; // px/ms

  /// LOCKED: forgiving flick so it works reliably.
  /// If the user intentionally swipes, it should succeed.
  bool get isFlick =>
      distance >= 28 &&      // was too high
      durationMs <= 220 &&   // allow slightly longer
      velocity >= 0.20;      // was too strict
}
