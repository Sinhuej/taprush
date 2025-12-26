#!/usr/bin/env bash
set -euo pipefail

echo "▶ Phase B.75 (B): Wire CheatDetector into tap pipeline (logic only)"

mkdir -p lib/anti_cheat

# ---------------------------
# lib/anti_cheat/cheat_detector.dart
# ---------------------------
cat > lib/anti_cheat/cheat_detector.dart << 'DART'
class CheatDetector {
  // Conservative to avoid false positives.
  // We punish the SESSION (spectacle), not the player account.
  static const int suspicionThreshold = 6;

  int _suspicion = 0;
  DateTime? _lastTap;
  final List<int> _intervalsMs = [];

  bool get cheatingDetected => _suspicion >= suspicionThreshold;

  void reset() {
    _suspicion = 0;
    _lastTap = null;
    _intervalsMs.clear();
  }

  void recordTap({
    required DateTime now,
    required bool perfectHit, // we may wire this later; safe to pass false for now
  }) {
    if (_lastTap != null) {
      final delta = now.difference(_lastTap!).inMilliseconds;
      _intervalsMs.add(delta);

      // Impossible reaction: ultra-fast repeated taps
      if (delta < 70) {
        _suspicion += 1;
      }

      // Robotic timing: low variance in intervals
      if (_intervalsMs.length >= 8) {
        final sum = _intervalsMs.fold<int>(0, (a, b) => a + b);
        final avg = sum / _intervalsMs.length;

        double variance = 0;
        for (final v in _intervalsMs) {
          final d = v - avg;
          variance += d * d;
        }
        variance /= _intervalsMs.length;

        // variance < ~15ms^2 is extremely uniform for humans
        if (variance < 15) {
          _suspicion += 3;
        }

        _intervalsMs.clear();
      }
    }

    // Perfect streaks can contribute later (optional)
    if (perfectHit) {
      _suspicion += 1;
    }

    _lastTap = now;
  }
}
DART

# ---------------------------
# lib/anti_cheat/cheat_sequence.dart
# ---------------------------
cat > lib/anti_cheat/cheat_sequence.dart << 'DART'
import 'dart:async';

enum CheatVisualPhase {
  pullIn,
  compress,
  explode,
}

class CheatSequence {
  CheatVisualPhase phase = CheatVisualPhase.pullIn;
  double progress = 0.0; // 0..1
  bool completed = false;

  Future<void> run({
    required void Function() onTick,
    int totalMs = 3000,
  }) async {
    const int stepMs = 16;
    int elapsed = 0;

    completed = false;
    progress = 0.0;
    phase = CheatVisualPhase.pullIn;

    while (elapsed < totalMs) {
      elapsed += stepMs;
      progress = elapsed / totalMs;

      if (progress < 0.34) {
        phase = CheatVisualPhase.pullIn;
      } else if (progress < 0.67) {
        phase = CheatVisualPhase.compress;
      } else {
        phase = CheatVisualPhase.explode;
      }

      onTick();
      await Future.delayed(const Duration(milliseconds: stepMs));
    }

    completed = true;
    onTick();
  }
}
DART

# ---------------------------
# lib/game/taprush_game_screen.dart
# (logic: detect -> 3s sequence -> game over, score=0)
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

    // If cheat is active, freeze gameplay (visuals will come in Step A)
    if (_cheatActive) return;

    final now = DateTime.now();
    final dt = now.difference(_last).inMilliseconds / 1000.0;
    _last = now;

    if (phase != GamePhase.playing) return;

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

    // Freeze run + disable taps immediately
    _cheatActive = true;
    setState(() {});

    // Run the 3s cinematic sequence (Step A will render it)
    await _cheatSeq.run(
      totalMs: 3000,
      onTick: () {
        if (!mounted) return;
        setState(() {});
      },
    );

    if (!mounted) return;

    // End run: no points, no coins (coins not implemented yet)
    // We enforce "no points" by showing score=0 when cheatTriggered.
    setState(() {
      phase = GamePhase.gameOver;
    });
  }

  void _onTapDown(TapDownDetails d) {
    if (phase != GamePhase.playing) return;
    if (_cheatActive) return;

    final now = DateTime.now();
    _cheat.recordTap(now: now, perfectHit: false);

    // Trigger cheat cinematic if detected
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

    final ok = engine.handleLaneTapAnywhere(
      lane: lane,
      tapY: d.localPosition.dy,
      maxDistancePx: maxDist,
    );

    // No more screen flashes (you hated them).
    // Step B.5 (later) will add per-tile check/x and accuracy bonus.

    if (engine.gameOver) {
      setState(() => phase = GamePhase.gameOver);
    } else {
      setState(() {});
    }

    // Extra: very fast repeated misses can also signal bots; detector already sees timing.
    // Keep it simple for now.
    if (!ok) {
      // nothing extra
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

    // Enforce "no points" if cheat triggered:
    final displayScore = _cheatTriggered ? 0 : snap.score;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Stack(
          children: [
            // Step A will use _cheatSeq to animate tiles.
            Board(
              laneCount: config.laneCount,
              tiles: snap.tiles,
              hitTop: -1,
              hitBottom: -1,
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

            // (Optional) small message during cheat sequence — not required.
            if (_cheatActive && phase == GamePhase.playing)
              Positioned(
                left: 0,
                right: 0,
                bottom: 60,
                child: Center(
                  child: Text(
                    _cheatSeq.phase == CheatVisualPhase.explode
                        ? 'Nice try.'
                        : '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
DART

echo "✅ Step B complete: detector wired + 3s cheat sequence + score zeroing"
