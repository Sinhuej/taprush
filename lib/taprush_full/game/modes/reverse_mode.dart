import 'mode.dart';
import 'mode_id.dart';
import 'tap_intent.dart';

class ReverseMode extends Mode {
  @override
  ModeId get id => ModeId.reverse;

  @override
  TapIntent transformRequired(TapIntent raw) {
    switch (raw) {
      case TapIntent.up:
        return TapIntent.down;
      case TapIntent.down:
        return TapIntent.up;
      case TapIntent.left:
        return TapIntent.right;
      case TapIntent.right:
        return TapIntent.left;
      case TapIntent.neutral:
        return TapIntent.neutral;
    }
  }
}
