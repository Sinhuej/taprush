import 'mode_id.dart';
import 'tap_intent.dart';
import 'device_lock.dart';

abstract class Mode {
  ModeId get id;

  int get uiRotationDegrees => 0;

  DeviceLock get deviceLock => DeviceLock.none;

  TapIntent transformRequired(TapIntent raw) => raw;

  bool get isDual => false;
}
