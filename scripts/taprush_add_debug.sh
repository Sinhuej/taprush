#!/usr/bin/env bash
set -e

echo "🛠️ Adding TapRush debug system..."

# Ensure debug directory exists
mkdir -p lib/taprush_core/debug

# -----------------------------
# Debug Log
# -----------------------------
cat > lib/taprush_core/debug/debug_log.dart <<'DART'
class DebugEvent {
  final double time;
  final String tag;
  final String message;

  DebugEvent(this.time, this.tag, this.message);
}

class DebugLog {
  static const int maxEvents = 300;
  static final List<DebugEvent> _events = [];

  static void log(String tag, String message, double time) {
    _events.add(DebugEvent(time, tag, message));
    if (_events.length > maxEvents) {
      _events.removeAt(0);
    }
  }

  static List<DebugEvent> snapshot() {
    return List.unmodifiable(_events);
  }

  static void clear() {
    _events.clear();
  }
}
DART

# -----------------------------
# Debug Overlay
# -----------------------------
cat > lib/taprush_core/debug/debug_overlay.dart <<'DART'
import 'package:flutter/material.dart';
import 'debug_log.dart';

class DebugOverlay extends StatelessWidget {
  const DebugOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final events = DebugLog.snapshot().reversed.toList();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 220,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: ListView(
          padding: const EdgeInsets.all(6),
          children: [
            for (final e in events)
              Text(
                '[${e.time.toStringAsFixed(2)}] ${e.tag}: ${e.message}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.greenAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
DART

echo "✅ Debug system installed."
echo "👉 Next: import DebugOverlay into PlayScreen Stack."
