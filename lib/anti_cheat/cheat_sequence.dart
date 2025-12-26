import 'dart:async';

enum CheatVisualPhase {
  pullIn,
  compress,
  explode,
}

class CheatSequence {
  CheatVisualPhase phase = CheatVisualPhase.pullIn;
  double progress = 0.0;

  bool _running = false;

  Future<void> run({
    required int totalMs,
    required VoidCallback onTick,
  }) async {
    if (_running) return;
    _running = true;

    // Phase timings (ms)
    final pullMs = (totalMs * 0.45).round();     // ~450ms
    final compressMs = (totalMs * 0.30).round(); // ~300ms
    final explodeMs = totalMs - pullMs - compressMs; // ~250ms

    Future<void> runPhase(
      CheatVisualPhase p,
      int durationMs,
    ) async {
      phase = p;
      progress = 0.0;

      final start = DateTime.now();
      final end = start.add(Duration(milliseconds: durationMs));

      while (true) {
        final now = DateTime.now();
        final elapsed = now.difference(start).inMilliseconds;
        progress = (elapsed / durationMs).clamp(0.0, 1.0);

        onTick();

        if (now.isAfter(end)) break;
        await Future.delayed(const Duration(milliseconds: 16)); // ~60fps
      }

      progress = 1.0;
      onTick();
    }

    await runPhase(CheatVisualPhase.pullIn, pullMs);
    await runPhase(CheatVisualPhase.compress, compressMs);
    await runPhase(CheatVisualPhase.explode, explodeMs);

    _running = false;
  }

  void reset() {
    phase = CheatVisualPhase.pullIn;
    progress = 0.0;
    _running = false;
  }
}
