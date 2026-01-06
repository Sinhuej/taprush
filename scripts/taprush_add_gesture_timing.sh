#!/usr/bin/env bash
set -e

echo "⏱ Adding per-gesture timing logs..."

ENGINE="lib/taprush_core/engine/game_engine.dart"

# Ensure debug import
grep -q "debug_log.dart" "$ENGINE" || \
sed -i "1i import '../debug/debug_log.dart';" "$ENGINE"

# Inject timing start
grep -q "final gestureStartTs" "$ENGINE" || \
sed -i "/InputResult onGesture/a\\
    final gestureStartTs = DateTime.now().millisecondsSinceEpoch;
" "$ENGINE"

# Inject timing end before return
grep -q "GESTURE_TIME" "$ENGINE" || \
sed -i "/return res;/i\\
    final gestureEndTs = DateTime.now().millisecondsSinceEpoch;\\
    DebugLog.log(\\
      'GESTURE_TIME',\\
      'duration=\${gestureEndTs - gestureStartTs}ms hit=\${res.hit} flick=\${res.flicked}',\\
      _time,\\
    );
" "$ENGINE"

echo "✅ Gesture timing instrumentation added"
