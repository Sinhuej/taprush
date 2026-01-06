#!/usr/bin/env bash
set -e

echo "🔧 Fixing TapRush debug build (sed-only, repo-safe)..."

ENGINE="lib/taprush_core/engine/game_engine.dart"

# --------------------------------------------------
# 1) Fix Debug Overlay (string-based)
# --------------------------------------------------
mkdir -p lib/taprush_core/debug

cat > lib/taprush_core/debug/debug_overlay.dart <<'DART'
import 'package:flutter/material.dart';
import 'debug_log.dart';

class DebugOverlay extends StatelessWidget {
  const DebugOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final lines = DebugLog.snapshot();

    return IgnorePointer(
      ignoring: false,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 220),
          padding: const EdgeInsets.all(8),
          color: Colors.black.withOpacity(0.75),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.2,
              fontFamily: 'monospace',
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: lines.length,
              itemBuilder: (context, i) {
                final e = lines[lines.length - 1 - i];
                return Text(e);
              },
            ),
          ),
        ),
      ),
    );
  }
}
DART

echo "✅ Debug overlay fixed"

# --------------------------------------------------
# 2) Replace Object.hash(...) with toString().hashCode
# --------------------------------------------------

sed -i '
/final gestureHash = Object.hash(/,/);/c\
    final gestureHash = gesture.toString().hashCode;
' "$ENGINE"

echo "✅ Gesture debounce hash fixed (no perl)"

echo "🎯 Debug build repair complete"
