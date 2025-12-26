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

const bool kEnableSecretCheatGesture = true;

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
    if (phase != GamePhase.playing) return;

    final now = DateTime.now();
    final dt = now.difference(_last).inMilliseconds / 1000.0;
    _last = now;

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

  void _restart() => _start();

  Future<void> _triggerCheatSequence() async {
    if (_cheatTriggered) return;

    _cheatTriggered = true;
    _cheatActive = true;
    setState(() {});

    await _cheatSeq.run(
      totalMs: 1000, // 🔥 1 second cinematic
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

    engine.handleLaneTapAnywhere(
      lane: lane,
      tapY: d.localPosition.dy,
      maxDistancePx: engine.tileHeight * 0.9,
    );

    if (engine.gameOver) {
      setState(() => phase = GamePhase.gameOver);
    } else {
      setState(() {});
    }
  }

  Future<void> _onSecretLongPress() async {
    if (!kEnableSecretCheatGesture) return;
    if (phase != GamePhase.playing) return;
    if (_cheatActive) return;

    await _triggerCheatSequence();
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
      onLongPress: _onSecretLongPress,
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
