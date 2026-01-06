#!/usr/bin/env bash
set -e

echo "🧪 Adding double-score detection..."

MODELS="lib/taprush_core/engine/models.dart"
ENGINE="lib/taprush_core/engine/game_engine.dart"

# Ensure consumed flag exists
grep -q "bool consumed" "$MODELS" || \
sed -i "/bool isBomb;/a\\
  bool consumed = false;
" "$MODELS"

# Add guard + logging
grep -q "DOUBLE_SCORE" "$ENGINE" || \
sed -i "/entities.remove(target);/i\\
    if (target.consumed) {\\
      DebugLog.log('DOUBLE_SCORE', 'Entity \${target.id} scored twice', _time);\\
      return const InputResult.miss();\\
    }\\
    target.consumed = true;
" "$ENGINE"

echo "✅ Double-score detection active"
