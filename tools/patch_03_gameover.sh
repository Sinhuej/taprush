#!/usr/bin/env bash
set -e

echo "🟥 Patch 03 — Game over & retry flow"

cat > lib/taprush_core/ui/play_screen.dart <<'EOF'
import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../engine/models.dart';

class PlayScreen extends StatefulWidget {
  final GameMode mode;
  const PlayScreen({super.key, required this.mode});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  late final TapRushEngine engine;
  late final Ticker _ticker;
  double _lastTime = 0;

  @override
  void initState() {
    super.initState();
    engine = TapRushEngine()..reset(newMode: widget.mode);

    _ticker = createTicker((elapsed) {
      final t = elapsed.inMicroseconds / 1e6;
      final dt = t - _lastTime;
      _lastTime = t;

      if (!engine.isGameOver) {
        engine.tick(dt);
        setState(() {});
      } else {
        _ticker.stop();
        setState(() {});
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _retry() {
    engine.reset(newMode: widget.mode);
    _lastTime = 0;
    _ticker.start();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (engine.isGameOver) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('GAME OVER',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              Text('Score: ${engine.stats.score}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _retry,
                child: const Text('RETRY'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('EXIT',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          // Tiles drawn elsewhere (unchanged)
          Positioned(
            top: 40,
            left: 20,
            child: Text(
              'Score ${engine.stats.score}   Lives ${TapRushEngine.maxStrikes - engine.stats.strikes}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
EOF

echo "✅ Patch 03 applied"

