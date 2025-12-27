import 'mode.dart';
import 'mode_id.dart';

class DualMode extends Mode {
  @override
  ModeId get id => ModeId.dual;

  @override
  bool get isDual => true;
}
