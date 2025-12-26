#!/usr/bin/env bash
set -e

echo "▶ Phase A: Start Screen + GamePhase"

# Ensure dirs exist
mkdir -p lib/game
mkdir -p lib/ui

# 1) GamePhase enum
cat > lib/game/game_phase.dart << 'DART'
enum GamePhase {
  idle,
  playing,
  gameOver,
}
DART

# 2) Start Overlay (B + C hybrid)
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
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'Tap to Start',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.1,
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

# 3) Wire into TapRushGameScreen
GAME_FILE="lib/game/taprush_game_screen.dart"

# Add imports if missing
grep -q "game_phase.dart" "$GAME_FILE" || \
  sed -i "1i import '../game/game_phase.dart';" "$GAME_FILE"

grep -q "start_overlay.dart" "$GAME_FILE" || \
  sed -i "1i import '../ui/start_overlay.dart';" "$GAME_FILE"

# Add phase state if missing
grep -q "GamePhase phase" "$GAME_FILE" || \
  sed -i "/class _/a\\
  GamePhase phase = GamePhase.idle;\\
" "$GAME_FILE"

# Gate the game loop (safe: no-op if already gated)
sed -i "s/void updateGame()/void updateGame() {\\n    if (phase != GamePhase.playing) return;/" "$GAME_FILE"

# Add startGame method if missing
grep -q "void startGame()" "$GAME_FILE" || \
  sed -i "/@override/a\\
  void startGame() {\\
    setState(() {\\
      phase = GamePhase.playing;\\
      strikes = 0;\\
      score = 0;\\
      stage = 0;\\
    });\\
  }\\
" "$GAME_FILE"

echo "✅ Phase A files written"
