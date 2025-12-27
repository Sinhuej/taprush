import 'mode.dart';
import 'mode_id.dart';
import 'device_lock.dart';

class SidewaysMode extends Mode {
  @override
  ModeId get id => ModeId.sideways;

  @override
  int get uiRotationDegrees => 90;

  /// LOCK: Sideways expects PORTRAIT. Rotating to landscape is cheating.
  @override
  DeviceLock get deviceLock => DeviceLock.portraitOnly;
}
