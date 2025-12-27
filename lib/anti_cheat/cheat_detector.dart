import 'cheat_event.dart';
import 'cheat_sequence.dart';

class CheatDetector {
  final CheatSequence visuals;
  bool _triggered = false;

  CheatDetector({required this.visuals});

  bool get hasTriggered => _triggered;

  void trigger(CheatEvent event) {
    if (_triggered) return;
    _triggered = true;

    // Fire the visual sequence (non-blocking)
    visuals.run(
      totalMs: 3000,
      onTick: () {},
    );
  }

  void reset() {
    _triggered = false;
    visuals.reset();
  }
}
