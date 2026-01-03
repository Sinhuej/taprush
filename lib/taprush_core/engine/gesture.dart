import 'dart:ui';

enum GestureType {
  tap,
  flick,
  ignore,
}

class GestureSample {
  final Offset start;
  final Offset end;
  final Duration startTime;
  final Duration endTime;

  GestureSample({
    required this.start,
    required this.end,
    required this.startTime,
    required this.endTime,
  });

  double get durationMs =>
      (endTime - startTime).inMicroseconds / 1000.0;

  Offset get delta => end - start;

  double get distanceSquared =>
      delta.dx * delta.dx + delta.dy * delta.dy;

  double get distance => delta.distance;

  double get velocity =>
      durationMs <= 0 ? 0 : distance / durationMs;

  GestureType classify() {
    // ---- GAME FEEL TUNING ----
    const double kTapMaxDurationMs = 200;
    const double kTapDistanceSq = 400; // 20px drift

    const double kFlickDistanceSq = 625; // 25px
    const double kFlickVelocityMin = 0.4;

    // TAP: short + contained
    if (durationMs <= kTapMaxDurationMs &&
        distanceSquared <= kTapDistanceSq) {
      return GestureType.tap;
    }

    // FLICK: intentional + fast
    if (distanceSquared >= kFlickDistanceSq &&
        velocity >= kFlickVelocityMin) {
      return GestureType.flick;
    }

    return GestureType.ignore;
  }

  @override
  String toString() {
    return 'GestureSample('
        'duration=${durationMs.toStringAsFixed(1)}ms, '
        'dist=${distance.toStringAsFixed(1)}, '
        'vel=${velocity.toStringAsFixed(2)}, '
        'type=${classify()}'
        ')';
  }
}
