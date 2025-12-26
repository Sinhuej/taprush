#!/usr/bin/env bash
set -e

GAME_FILE="lib/game/taprush_game_screen.dart"

echo "▶ Phase A (SAFE): Start Screen + Phase Gate"

# Ensure enum exists
mkdir -p lib/game
cat > lib/game/game_phase.dart << 'DART'
enum GamePhase {
  idle,
  playing,
  gameOver,
}
DART

# Ensure overlay exists
mkdir -p lib/ui
cat > lib/ui/start_overlay.dart << 'DART'
import 'package:flutter/material.dart';

class StartOverlay extends StatelessWidget {
  final VoidCallback onStart;
  const StartOverlay({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Text(
                'Tap to Start',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
DART

# Add imports if missing
grep -q game_phase.dart "$GAME_FILE" || sed -i "1i import '../game/game_phase.dart';" "$GAME_FILE"
grep -q start_overlay.dart "$GAME_FILE" || sed -i "1i import '../ui/start_overlay.dart';" "$GAME_FILE"

# Add phase field inside State class ONLY
grep -q "GamePhase phase" "$GAME_FILE" || \
sed -i "/class _TapRushGameScreenState/a\\
  GamePhase phase = GamePhase.idle;\\
" "$GAME_FILE"

# Gate update loop (non-destructive)
sed -i "s/void updateGame()/void updateGame() {\\n    if (phase != GamePhase.playing) return;/" "$GAME_FILE"

# Render overlay in Stack
sed -i "/Stack(/a\\
        if (phase == GamePhase.idle)\\
          StartOverlay(onStart: () => setState(() => phase = GamePhase.playing)),\\
" "$GAME_FILE"

echo "✅ Phase A applied safely"
