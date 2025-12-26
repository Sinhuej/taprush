#!/usr/bin/env bash
set -euo pipefail

echo "▶ Phase B: Tap-anywhere input (no zones), closest-tile selection, miss if none close"

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
  double spawnEverySec = 0.58;

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

    for (final t in _tiles) {
      t.y += speedPxPerSec * dt;
    }

    // tile exits bottom => strike
    _tiles.removeWhere((t) {
      final gone = t.y > screenH + 40;
      if (gone) _strike();
      return gone;
    });

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

  void _strike() {
    strikes += 1;
    if (strikes >= maxStrikes) gameOver = true;
  }

  /// Tap-anywhere behavior:
  /// - Lane is chosen by UI (based on tap X)
  /// - We select the tile in that lane whose CENTER is closest to tapY
  /// - We only allow a hit if it's within [maxDistancePx] of tapY
  /// - Otherwise it's a miss (strike)
  bool handleLaneTapAnywhere({
    required int lane,
    required double tapY,
    required double maxDistancePx,
  }) {
    if (gameOver) return false;

    Tile? best;
    double bestDist = 1e18;

    for (final t in _tiles) {
      if (t.lane != lane) continue;

      final centerY = t.y + (t.height / 2.0);
      final dist = (centerY - tapY).abs();

      if (dist < bestDist) {
        bestDist = dist;
        best = t;
      }
    }

    // A: miss if not reasonably close
    if (best == null || bestDist > maxDistancePx) {
      _strike();
      return false;
    }

    _tiles.remove(best);
    score += 1;
    return true;
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

  // feedback
  bool _flash = false;
  bool _hit = false;

  @override
  void initState() {
    super.initState();
    engine = TileEngine(
      laneCount: config.laneCount,
      maxStrikes: config.maxStrikes,
    );
    engine.reset();

    _last = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;

    final now = DateTime.now();
    final dt = now.difference(_last).inMilliseconds / 1000.0;
    _last = now;

    if (phase != GamePhase.playing) return;

    final screenH = MediaQuery.of(context).size.height;

    // Phase B curve: slower start + smoother ramp
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

  void _flashFeedback(bool hit) {
    _flash = true;
    _hit = hit;
    setState(() {});
    Future.delayed(Duration(milliseconds: config.feedbackMs), () {
      if (!mounted) return;
      _flash = false;
      setState(() {});
    });
  }

  void _onTapDown(TapDownDetails d) {
    if (phase != GamePhase.playing) return;

    final size = MediaQuery.of(context).size;

    final lane = resolveLane(
      tapX: d.localPosition.dx,
      screenW: size.width,
      laneCount: config.laneCount,
    );

    // Reasonable closeness threshold:
    // ~0.8 tile height + a small buffer feels fair without becoming “auto-hit”.
    final maxDist = (engine.tileHeight * 0.80) + 24.0;

    final ok = engine.handleLaneTapAnywhere(
      lane: lane,
      tapY: d.localPosition.dy,
      maxDistancePx: maxDist,
    );

    _flashFeedback(ok);

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
    final snap = engine.snapshot();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Stack(
          children: [
            // Board stays simple: lanes + tiles.
            // No zones/lines (future-proof for all modes).
            Board(
              laneCount: config.laneCount,
              tiles: snap.tiles,
              hitTop: -1,     // ignored visually if board draws it; keep signature stable
              hitBottom: -1,  // ignored visually if board draws it; keep signature stable
            ),

            Hud(
              score: snap.score,
              strikes: snap.strikes,
              maxStrikes: config.maxStrikes,
            ),

            if (_flash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: (_hit ? Colors.green : Colors.red).withOpacity(0.10),
                  ),
                ),
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

echo "✅ Phase B tap-anywhere applied."
