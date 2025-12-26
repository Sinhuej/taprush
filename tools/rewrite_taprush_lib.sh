#!/usr/bin/env bash
set -euo pipefail

echo "🧱 SlimNation: Full lib/ rewrite (cat-only) starting..."

# DANGER: full rewrite
rm -rf lib
mkdir -p lib/{app,game,engine,input,ui,economy,skins,bg,ads,settings}

# ---------------------------
# lib/main.dart
# ---------------------------
cat > lib/main.dart << 'DART'
import 'package:flutter/material.dart';
import 'app/taprush_app.dart';

void main() {
  runApp(const TapRushApp());
}
DART

# ---------------------------
# lib/app/taprush_app.dart
# ---------------------------
cat > lib/app/taprush_app.dart << 'DART'
import 'package:flutter/material.dart';
import '../game/taprush_game_screen.dart';

class TapRushApp extends StatelessWidget {
  const TapRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapRush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TapRushGameScreen(),
    );
  }
}
DART

# ---------------------------
# lib/game/game_phase.dart
# ---------------------------
cat > lib/game/game_phase.dart << 'DART'
enum GamePhase {
  idle,
  playing,
  gameOver,
}
DART

# ---------------------------
# lib/game/game_config.dart
# ---------------------------
cat > lib/game/game_config.dart << 'DART'
class GameConfig {
  final int laneCount;
  final int maxStrikes;

  // starting difficulty (Phase C will refine)
  final double baseSpeed;      // px/sec
  final double rampPerScore;   // px/sec per score

  // hit tuning (Phase B will refine)
  final double hitZoneTopPct;    // of screen height
  final double hitZoneBottomPct; // of screen height
  final double hitLeniencyPx;    // forgiveness in pixels

  const GameConfig({
    this.laneCount = 6,
    this.maxStrikes = 5,
    this.baseSpeed = 520,         // slower start (playable)
    this.rampPerScore = 14,       // gentle ramp for now
    this.hitZoneTopPct = 0.78,
    this.hitZoneBottomPct = 0.90,
    this.hitLeniencyPx = 26,
  });
}
DART

# ---------------------------
# lib/engine/models.dart
# ---------------------------
cat > lib/engine/models.dart << 'DART'
class Tile {
  final int id;
  final int lane;     // 0..laneCount-1
  double y;           // top-left Y
  final double height;

  Tile({
    required this.id,
    required this.lane,
    required this.y,
    required this.height,
  });
}

class EngineSnapshot {
  final List<Tile> tiles;
  final int score;
  final int strikes;
  final bool gameOver;

  const EngineSnapshot({
    required this.tiles,
    required this.score,
    required this.strikes,
    required this.gameOver,
  });
}
DART

# ---------------------------
# lib/engine/tile_engine.dart
# ---------------------------
cat > lib/engine/tile_engine.dart << 'DART'
import 'dart:math';
import 'models.dart';

class TileEngine {
  final int laneCount;
  final int maxStrikes;

  int _nextId = 1;
  final Random _rng = Random();

  final List<Tile> _tiles = [];

  int score = 0;
  int strikes = 0;
  bool gameOver = false;

  // spawn tuning
  double _spawnTimer = 0;
  double spawnEverySec = 0.55; // later can tighten

  // tile tuning
  double tileHeight = 140;

  TileEngine({
    required this.laneCount,
    required this.maxStrikes,
  });

  void reset() {
    _nextId = 1;
    _tiles.clear();
    score = 0;
    strikes = 0;
    gameOver = false;
    _spawnTimer = 0;
  }

  List<Tile> get tiles => _tiles;

  void tick({
    required double dt,
    required double screenH,
    required double speedPxPerSec,
  }) {
    if (gameOver) return;

    // move tiles
    for (final t in _tiles) {
      t.y += speedPxPerSec * dt;
    }

    // remove tiles that fell past bottom (strike)
    _tiles.removeWhere((t) {
      final gone = t.y > screenH + 40;
      if (gone) {
        strikes += 1;
        if (strikes >= maxStrikes) gameOver = true;
      }
      return gone;
    });

    // spawn logic
    _spawnTimer += dt;
    if (_spawnTimer >= spawnEverySec) {
      _spawnTimer = 0;
      _spawnOne();
    }
  }

  void _spawnOne() {
    final lane = _rng.nextInt(laneCount);
    _tiles.add(Tile(
      id: _nextId++,
      lane: lane,
      y: -tileHeight - _rng.nextInt(120).toDouble(),
      height: tileHeight,
    ));
  }

  bool handleLaneTap({
    required int lane,
    required double hitTop,
    required double hitBottom,
    required double leniencyPx,
  }) {
    if (gameOver) return false;

    // choose the tile in that lane closest to the hit zone
    Tile? best;
    double bestDist = 1e18;

    for (final t in _tiles) {
      if (t.lane != lane) continue;

      final tileTop = t.y;
      final tileBottom = t.y + t.height;

      // overlap check with leniency
      final overlaps = (tileBottom >= (hitTop - leniencyPx)) &&
          (tileTop <= (hitBottom + leniencyPx));

      if (!overlaps) continue;

      // distance to center of hit zone
      final tileCenter = (tileTop + tileBottom) / 2.0;
      final zoneCenter = (hitTop + hitBottom) / 2.0;
      final dist = (tileCenter - zoneCenter).abs();

      if (dist < bestDist) {
        bestDist = dist;
        best = t;
      }
    }

    if (best != null) {
      _tiles.remove(best);
      score += 1;
      return true;
    }

    // miss -> strike
    strikes += 1;
    if (strikes >= maxStrikes) gameOver = true;
    return false;
  }

  EngineSnapshot snapshot() {
    return EngineSnapshot(
      tiles: List.unmodifiable(_tiles),
      score: score,
      strikes: strikes,
      gameOver: gameOver,
    );
  }
}
DART

# ---------------------------
# lib/input/lane_resolver.dart
# ---------------------------
cat > lib/input/lane_resolver.dart << 'DART'
int resolveLane({
  required double tapX,
  required double screenW,
  required int laneCount,
}) {
  final laneW = screenW / laneCount;
  final lane = (tapX / laneW).floor();
  if (lane < 0) return 0;
  if (lane >= laneCount) return laneCount - 1;
  return lane;
}
DART

# ---------------------------
# lib/ui/start_overlay.dart  (B + C: modern + button)
# ---------------------------
cat > lib/ui/start_overlay.dart << 'DART'
import 'package:flutter/material.dart';

class StartOverlay extends StatelessWidget {
  final VoidCallback onStart;

  const StartOverlay({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.78),
        child: Center(
          child: GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white24),
                color: Colors.white.withOpacity(0.10),
              ),
              child: const Text(
                'Tap to Start',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.0,
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

# ---------------------------
# lib/ui/game_over_overlay.dart
# ---------------------------
cat > lib/ui/game_over_overlay.dart << 'DART'
import 'package:flutter/material.dart';

class GameOverOverlay extends StatelessWidget {
  final int score;
  final int strikes;
  final VoidCallback onRestart;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.strikes,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.82),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
              color: Colors.white.withOpacity(0.10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Game Over',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Score: $score'),
                Text('Strikes: $strikes'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRestart,
                  child: const Text('Play Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
DART

# ---------------------------
# lib/ui/hud.dart
# ---------------------------
cat > lib/ui/hud.dart << 'DART'
import 'package:flutter/material.dart';

class Hud extends StatelessWidget {
  final int score;
  final int strikes;
  final int maxStrikes;

  const Hud({
    super.key,
    required this.score,
    required this.strikes,
    required this.maxStrikes,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SCORE $score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('STRIKES $strikes/$maxStrikes', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
DART

# ---------------------------
# lib/ui/board.dart
# ---------------------------
cat > lib/ui/board.dart << 'DART'
import 'package:flutter/material.dart';
import '../engine/models.dart';

class Board extends StatelessWidget {
  final int laneCount;
  final List<Tile> tiles;
  final double hitTop;
  final double hitBottom;

  const Board({
    super.key,
    required this.laneCount,
    required this.tiles,
    required this.hitTop,
    required this.hitBottom,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final laneW = w / laneCount;

      return Stack(
        children: [
          // Background
          Container(color: const Color(0xFF0D1117)),

          // Lane dividers
          for (int i = 1; i < laneCount; i++)
            Positioned(
              left: i * laneW,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: Colors.white12),
            ),

          // Hit zone
          Positioned(
            left: 0,
            right: 0,
            top: hitTop,
            child: Container(
              height: (hitBottom - hitTop).clamp(0, h),
              color: Colors.white10,
            ),
          ),

          // Tiles
          for (final t in tiles)
            Positioned(
              left: t.lane * laneW + 8,
              top: t.y,
              child: Container(
                width: laneW - 16,
                height: t.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.18),
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
        ],
      );
    });
  }
}
DART

# ---------------------------
# lib/game/taprush_game_screen.dart
# ---------------------------
cat > lib/game/taprush_game_screen.dart << 'DART'
import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/tile_engine.dart';
import '../game/game_config.dart';
import '../game/game_phase.dart';
import '../input/lane_resolver.dart';
import '../ui/board.dart';
import '../ui/game_over_overlay.dart';
import '../ui/hud.dart';
import '../ui/start_overlay.dart';

class TapRushGameScreen extends StatefulWidget {
  const TapRushGameScreen({super.key});

  @override
  State<TapRushGameScreen> createState() => _TapRushGameScreenState();
}

class _TapRushGameScreenState extends State<TapRushGameScreen> {
  final GameConfig config = const GameConfig();

  late final TileEngine engine;

  GamePhase phase = GamePhase.idle;

  Timer? _timer;
  DateTime _last = DateTime.now();

  // cached hit zone pixels
  double _hitTop = 0;
  double _hitBottom = 0;

  @override
  void initState() {
    super.initState();
    engine = TileEngine(
      laneCount: config.laneCount,
      maxStrikes: config.maxStrikes,
    );
    engine.reset();

    // tick loop
    _last = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;

    final now = DateTime.now();
    final dt = now.difference(_last).inMilliseconds / 1000.0;
    _last = now;

    if (phase != GamePhase.playing) {
      // don’t advance gameplay while idle/gameOver
      return;
    }

    final screenH = MediaQuery.of(context).size.height;

    final speed = config.baseSpeed + (engine.score * config.rampPerScore);

    engine.tick(
      dt: dt,
      screenH: screenH,
      speedPxPerSec: speed,
    );

    if (engine.gameOver) {
      setState(() => phase = GamePhase.gameOver);
      return;
    }

    setState(() {});
  }

  void _start() {
    engine.reset();
    setState(() => phase = GamePhase.playing);
  }

  void _restart() {
    engine.reset();
    setState(() => phase = GamePhase.playing);
  }

  void _onTapDown(TapDownDetails d) {
    if (phase != GamePhase.playing) return;

    final size = MediaQuery.of(context).size;
    final lane = resolveLane(
      tapX: d.localPosition.dx,
      screenW: size.width,
      laneCount: config.laneCount,
    );

    engine.handleLaneTap(
      lane: lane,
      hitTop: _hitTop,
      hitBottom: _hitBottom,
      leniencyPx: config.hitLeniencyPx,
    );

    if (engine.gameOver) {
      setState(() => phase = GamePhase.gameOver);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    _hitTop = h * config.hitZoneTopPct;
    _hitBottom = h * config.hitZoneBottomPct;

    final snap = engine.snapshot();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Stack(
          children: [
            Board(
              laneCount: config.laneCount,
              tiles: snap.tiles,
              hitTop: _hitTop,
              hitBottom: _hitBottom,
            ),

            Hud(
              score: snap.score,
              strikes: snap.strikes,
              maxStrikes: config.maxStrikes,
            ),

            if (phase == GamePhase.idle)
              StartOverlay(onStart: _start),

            if (phase == GamePhase.gameOver)
              GameOverOverlay(
                score: snap.score,
                strikes: snap.strikes,
                onRestart: _restart,
              ),
          ],
        ),
      ),
    );
  }
}
DART

echo "✅ SlimNation rewrite complete: lib/ rebuilt cleanly."
