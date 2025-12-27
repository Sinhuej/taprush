import 'cheat_detector.dart';
import 'cheat_event.dart';

enum DeviceOrientationState {
  portrait,
  landscapeLeft,
  landscapeRight,
}

class OrientationGuard {
  final CheatDetector detector;
  final DeviceOrientationState expected;

  OrientationGuard({
    required this.detector,
    required this.expected,
  });

  void onOrientationChanged(DeviceOrientationState current) {
    if (current != expected) {
      detector.trigger(
        CheatEvent(
          type: CheatType.orientationManipulation,
          reason:
              'Device rotated during Sideways mode to gain advantage.',
        ),
      );
    }
  }
}
