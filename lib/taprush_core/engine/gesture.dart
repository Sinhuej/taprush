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

  /// Total gesture duration in milliseconds
  double get durationMs =>
      (endTime - startTime).inMicroseconds / 1000.0;

  /// Delta vector
  Offset get delta => end - start;

  /// Squared distance (cheap, deterministic)
  double get distanceSquared =>
      delta.dx * delta.dx + delta.dy * delta.dy;

  /// Distance in pixels
  double get distance => delta.distance;

  /// Velocity in px/ms
  double get velocity =>
      durationMs <= 0 ? 0 : distance / durationMs;

  /// Primary axis movement (prevents jitter flicks)
  double get primaryAxisMagnitude =>
      delta.dx.abs() > delta.dy.abs()
          ? delta.dx.abs()
          : delta.dy.abs();

  GestureType classify() {
    // ---- Tunable thresholds (TapRush feel) ----

    // Flick tuning
    const double kFlickDistanceSq = 900;      // 30px^2
    const double kFlickVelocityMin = 0.7;     // px/ms
    const double kFlickMinDurationMs = 25;    // prevent spikes
    const double kFlickPrimaryAxisMin = 22;   // directional intent

    // Tap tuning
    const double kTapMaxDurationMs = 160;
    const double kTapMaxDistanceSq = 400;     // 20px^2

    // ---- Flick: fast, far, intentional ----
    if (durationMs >= kFlickMinDurationMs &&
        distanceSquared >= kFlickDistanceSq &&
        velocity >= kFlickVelocityMin &&
        primaryAxisMagnitude >= kFlickPrimaryAxisMin) {
      return GestureType.flick;
    }

    // ---- Tap: quick and still ----
    if (durationMs <= kTapMaxDurationMs &&
        distanceSquared <= kTapMaxDistanceSq) {
      return GestureType.tap;
    }

    return GestureType.ignore;
  }

  @override
  String toString() {
    return 'GestureSample('
        'durationMs=${durationMs.toStringAsFixed(1)}, '
        'distance=${distance.toStringAsFixed(1)}, '
        'velocity=${velocity.toStringAsFixed(2)}, '
        'type=${classify()}'
        ')';
  }
}
