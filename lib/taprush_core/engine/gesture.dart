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

  bool get isTap => distance < 12;

  bool get isFlick =>
      distance >= 28 &&
      durationMs <= 240;
}
