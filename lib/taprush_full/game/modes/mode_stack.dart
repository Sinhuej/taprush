import 'mode.dart';
import 'tap_intent.dart';
import 'device_lock.dart';

class ModeStack {
  final List<Mode> modes;
  const ModeStack(this.modes);

  TapIntent transformRequired(TapIntent raw) {
    var intent = raw;
    for (final m in modes) {
      intent = m.transformRequired(intent);
    }
    return intent;
  }

  int get uiRotationDegrees {
    for (var i = modes.length - 1; i >= 0; i--) {
      final deg = modes[i].uiRotationDegrees;
      if (deg != 0) return deg;
    }
    return 0;
  }

  bool get isDual => modes.any((m) => m.isDual);

  DeviceLock get deviceLock {
    for (var i = modes.length - 1; i >= 0; i--) {
      final lock = modes[i].deviceLock;
      if (lock != DeviceLock.none) return lock;
    }
    return DeviceLock.none;
  }
}
