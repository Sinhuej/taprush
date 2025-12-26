class CheatDetector {
  // Conservative to avoid false positives.
  // We punish the SESSION (spectacle), not the player account.
  static const int suspicionThreshold = 6;

  int _suspicion = 0;
  DateTime? _lastTap;
  final List<int> _intervalsMs = [];

  bool get cheatingDetected => _suspicion >= suspicionThreshold;

  void reset() {
    _suspicion = 0;
    _lastTap = null;
    _intervalsMs.clear();
  }

  void recordTap({
    required DateTime now,
    required bool perfectHit, // we may wire this later; safe to pass false for now
  }) {
    if (_lastTap != null) {
      final delta = now.difference(_lastTap!).inMilliseconds;
      _intervalsMs.add(delta);

      // Impossible reaction: ultra-fast repeated taps
      if (delta < 70) {
        _suspicion += 1;
      }

      // Robotic timing: low variance in intervals
      if (_intervalsMs.length >= 8) {
        final sum = _intervalsMs.fold<int>(0, (a, b) => a + b);
        final avg = sum / _intervalsMs.length;

        double variance = 0;
        for (final v in _intervalsMs) {
          final d = v - avg;
          variance += d * d;
        }
        variance /= _intervalsMs.length;

        // variance < ~15ms^2 is extremely uniform for humans
        if (variance < 15) {
          _suspicion += 3;
        }

        _intervalsMs.clear();
      }
    }

    // Perfect streaks can contribute later (optional)
    if (perfectHit) {
      _suspicion += 1;
    }

    _lastTap = now;
  }
}
