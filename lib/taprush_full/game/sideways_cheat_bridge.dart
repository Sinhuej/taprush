import '../platform/orientation_util.dart';
import 'modes/device_lock.dart';
import '../../anti_cheat/cheat_detector.dart';
import '../../anti_cheat/cheat_event.dart';

class SidewaysCheatBridge {
  final CheatDetector detector;

  SidewaysCheatBridge(this.detector);

  void check({
    required DeviceLock lock,
    required SimpleOrientation current,
  }) {
    // LOCKED RULE:
    // Sideways expects portrait. Rotating to landscape = cheating.
    if (lock == DeviceLock.portraitOnly && current == SimpleOrientation.landscape) {
      detector.trigger(
        CheatEvent(
          type: CheatType.orientationManipulation,
          reason: 'Rotated phone during Sideways mode to gain advantage.',
        ),
      );
    }

    if (lock == DeviceLock.landscapeOnly && current == SimpleOrientation.portrait) {
      detector.trigger(
        CheatEvent(
          type: CheatType.orientationManipulation,
          reason: 'Rotated phone against required orientation to gain advantage.',
        ),
      );
    }
  }
}
