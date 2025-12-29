#!/usr/bin/env bash
set -e

echo "🟢 TapRush master patch starting..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/patch_01_input.sh"
bash "$SCRIPT_DIR/patch_02_bombs.sh"
bash "$SCRIPT_DIR/patch_03_gameover.sh"
bash "$SCRIPT_DIR/patch_04_visuals.sh"

echo "✅ All TapRush patches applied successfully."
