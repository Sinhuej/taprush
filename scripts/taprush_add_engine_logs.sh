#!/usr/bin/env bash
set -e

echo "🧠 Adding gesture + score logging..."

ENGINE="lib/taprush_core/engine/game_engine.dart"

# Ensure import
grep -q "debug_log.dart" "$ENGINE" || \
sed -i "1i import '../debug/debug_log.dart';" "$ENGINE"

# Log entry into onGesture
grep -q "DebugLog.log('GESTURE'" "$ENGINE" || \
sed -i "/InputResult onGesture/a\\
    DebugLog.log('GESTURE', gesture.toString(), _time);
" "$ENGINE"

# Log successful hit
grep -q "DebugLog.log('HIT'" "$ENGINE" || \
sed -i "/entities.remove(target);/a\\
    DebugLog.log('HIT', 'id=\${target.id} bomb=\${target.isBomb} flick=\${res.flicked}', _time);
" "$ENGINE"

# Log score change
grep -q "DebugLog.log('SCORE'" "$ENGINE" || \
sed -i "/stats.onGood/a\\
    DebugLog.log('SCORE', 'score=\${stats.score}', _time);
" "$ENGINE"

echo "✅ Gesture + score logging added"
