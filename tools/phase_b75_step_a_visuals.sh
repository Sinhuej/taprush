#!/usr/bin/env bash
set -euo pipefail

echo "▶ Step A: Anti-cheat cinematic visuals (pull-in → compress → explode)"

# ---------------------------
# lib/ui/board.dart
# ---------------------------
cat > lib/ui/board.dart << 'DART'
import 'dart:math';
import 'package:flutter/material.dart';
import '../engine/models.dart';
import '../anti_cheat/cheat_sequence.dart';

class Board extends StatelessWidget {
  final int laneCount;
  final List<Tile> tiles;

  // Anti-cheat visuals (nullable when inactive)
  final CheatSequence? cheatSeq;

  const Board({
    super.key,
    required this.laneCount,
    required this.tiles,
    this.cheatSeq,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final laneW = w / laneCount;
      final center = Offset(w / 2, h / 2);

      Offset transformedPos(Tile t) {
        final baseX = t.lane * laneW + 8;
        final baseY = t.y;
        final base = Offset(baseX, baseY);

        if (cheatSeq == null) return base;

        final p = cheatSeq!.progress.clamp(0.0, 1.0);
        switch (cheatSeq!.phase) {
          case CheatVisualPhase.pullIn:
            return Offset.lerp(base, center, p * 0.85)!;
          case CheatVisualPhase.compress:
            final jitter = (Random(t.id).nextDouble() - 0.5) * 6.0;
            return Offset(
              base.dx + jitter,
              base.dy + sin(p * pi * 6) * 4,
            );
          case CheatVisualPhase.explode:
            final dir = (base - center);
            final norm = dir.distance == 0 ? Offset(1, 0) : dir / dir.distance;
            return base + norm * (p * 420);
        }
      }

      double transformedScale() {
        if (cheatSeq == null) return 1.0;
        final p = cheatSeq!.progress;
        switch (cheatSeq!.phase) {
          case CheatVisualPhase.pullIn:
            return 1.0;
          case CheatVisualPhase.compress:
            return 1.0 - (p * 0.25);
          case CheatVisualPhase.explode:
            return max(0.2, 1.0 - p);
        }
      }

      double transformedOpacity() {
        if (cheatSeq == null) return 1.0;
        if (cheatSeq!.phase == CheatVisualPhase.explode) {
          return max(0.0, 1.0 - cheatSeq!.progress);
        }
        return 1.0;
      }

      return Stack(
        children: [
          Container(color: const Color(0xFF0D1117)),

          // Lane dividers
          for (int i = 1; i < laneCount; i++)
            Positioned(
              left: i * laneW,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: Colors.white12),
            ),

          // Tiles
          for (final t in tiles)
            Builder(builder: (_) {
              final pos = transformedPos(t);
              return Positioned(
                left: pos.dx,
                top: pos.dy,
                child: Opacity(
                  opacity: transformedOpacity(),
                  child: Transform.scale(
                    scale: transformedScale(),
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
                ),
              );
            }),
        ],
      );
    });
  }
}
DART

# ---------------------------
# lib/game/taprush_game_screen.dart
# (pass cheat sequence into Board)
# ---------------------------
cat > lib/game/taprush_game_screen.dart << 'DART'
import 'dart:async';
import 'package:flutter/material.dart';

import '../anti_cheat/cheat_detector.dart';
import '../anti_cheat/cheat_sequence.dart';
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

  // Anti-cheat
  final CheatDetector _cheat = CheatDetector();
  final CheatSequence _cheatSeq = CheatSequence();
  bool _cheatActive = false;
  bool _cheatTriggered = false;

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
    if (_cheatActive) return;

    final now = DateTime.now();
    final dt = now.difference(_last).inMilliseconds / 1000.0;
    _last = now;

    if (phase != GamePhase.playing) return;

    final screenH = MediaQuery.of(context).size.height;
    final speed = config.baseSpeed + (engine.score * config.rampPerScore);

    engine.tick(dt: dt, screenH: screenH, speedPxPerSec: speed);

    if (engine.gameOver) {
      setState(() => phase = GamePhase.gameOver);
      return;
    }
    setState(() {});
  }

  void _start() {
    engine.reset();
    _cheat.reset();
    _cheatActive = false;
    _cheatTriggered = false;
    setState(() => phase = GamePhase.playing);
  }

  void _restart() {
    engine.reset();
    _cheat.reset();
    _cheatActive = false;
    _cheatTriggered = false;
    setState(() => phase = GamePhase.playing);
  }

  Future<void> _triggerCheatSequence() async {
    if (_cheatTriggered) return;
    _cheatTriggered = true;
    _cheatActive = true;
    setState(() {});

    await _cheatSeq.run(
      totalMs: 3000,
      onTick: () {
        if (mounted) setState(() {});
      },
    );

    if (!mounted) return;
    setState(() => phase = GamePhase.gameOver);
  }

  void _onTapDown(TapDownDetails d) {
    if (phase != GamePhase.playing) return;
    if (_cheatActive) return;

    _cheat.recordTap(now: DateTime.now(), perfectHit: false);

    if (_cheat.cheatingDetected) {
      _triggerCheatSequence();
      return;
    }

    final size = MediaQuery.of(context).size;
    final lane = resolveLane(
      tapX: d.localPosition.dx,
      screenW: size.width,
      laneCount: config.laneCount,
    );

    final maxDist = (engine.tileHeight * 0.80) + 24.0;
    engine.handleLaneTapAnywhere(
      lane: lane,
      tapY: d.localPosition.dy,
      maxDistancePx: maxDist,
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
    final snap = engine.snapshot();
    final displayScore = _cheatTriggered ? 0 : snap.score;

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
              cheatSeq: _cheatActive ? _cheatSeq : null,
            ),

            Hud(
              score: displayScore,
              strikes: snap.strikes,
              maxStrikes: config.maxStrikes,
            ),

            if (phase == GamePhase.idle)
              StartOverlay(onStart: _start),

            if (phase == GamePhase.gameOver)
              GameOverOverlay(
                score: displayScore,
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

echo "✅ Step A visuals applied."
