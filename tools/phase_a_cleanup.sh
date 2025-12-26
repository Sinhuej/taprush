#!/usr/bin/env bash
set -e

GAME_FILE="lib/game/taprush_game_screen.dart"

echo "🧹 Cleaning duplicate Phase A injections..."

# Remove duplicated startGame methods (keep first occurrence)
awk '
  BEGIN { count=0 }
  /void startGame\(/ {
    count++
    if (count > 1) { skip=1 }
  }
  skip && /}/ { skip=0; next }
  !skip { print }
' "$GAME_FILE" > "$GAME_FILE.tmp" && mv "$GAME_FILE.tmp" "$GAME_FILE"

# Remove any startGame accidentally injected into Widget class
sed -i '/class TapRushGameScreen/,/class _TapRushGameScreenState/{
  /void startGame/,/}/d
}' "$GAME_FILE"

echo "✅ Cleanup complete"
