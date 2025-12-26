import 'dart:async';

enum CheatVisualPhase {
  pullIn,
  compress,
  explode,
}

class CheatSequence {
  CheatVisualPhase phase = CheatVisualPhase.pullIn;
  double progress = 0.0; // 0..1
  bool completed = false;

  Future<void> run({
    required void Function() onTick,
    int totalMs = 3000,
  }) async {
    const int stepMs = 16;
    int elapsed = 0;

    completed = false;
    progress = 0.0;
    phase = CheatVisualPhase.pullIn;

    while (elapsed < totalMs) {
      elapsed += stepMs;
      progress = elapsed / totalMs;

      if (progress < 0.34) {
        phase = CheatVisualPhase.pullIn;
      } else if (progress < 0.67) {
        phase = CheatVisualPhase.compress;
      } else {
        phase = CheatVisualPhase.explode;
      }

      onTick();
      await Future.delayed(const Duration(milliseconds: stepMs));
    }

    completed = true;
    onTick();
  }
}
