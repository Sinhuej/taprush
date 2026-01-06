#!/usr/bin/env bash
set -e

echo "🔌 Wiring DebugOverlay into PlayScreen..."

FILE="lib/taprush_core/ui/play_screen.dart"

# Ensure import exists
grep -q "debug_overlay.dart" "$FILE" || \
sed -i "1i import '../debug/debug_overlay.dart';" "$FILE"

# Inject overlay into Stack if not present
grep -q "DebugOverlay" "$FILE" || \
sed -i "/children: \[/a\\
              const DebugOverlay(),
" "$FILE"

echo "✅ DebugOverlay wired into PlayScreen Stack"
