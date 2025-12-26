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
import '../visuals/color_mode.dart';
import '../economy/cosmetic_unlocks.dart';

class TapRushGameScreen extends StatefulWidget {
  const TapRushGameScreen({super.key});

  @override
  State<TapRushGameScreen> createState() => _TapRushGameScreenState();
}

class _TapRushGameScreenState extends State<TapRushGameScreen> {
  final GameConfig config = const GameConfig();
  final CosmeticUnlocks cosmetics = CosmeticUnlocks();

  late final TileEngine engine;
  final CheatDetector cheat = CheatDetector();
  final CheatSequence cheatSeq = CheatSequence();

  GamePhase phase = GamePhase.idle;
  bool cheatActive = false;

  Timer? timer;
  DateTime last = DateTime.now();

  @override
  void initState() {
    super.initState();
    engine = TileEngine(
      laneCount: config.laneCount,
      maxStrikes: config.maxStrikes,
    );
    engine.reset();
    timer = Timer.periodic(const Duration(milliseconds: 16), (_) => tick());
  }

  void tick() {
    if (!mounted || phase != GamePhase.playing || cheatActive) return;

    final now = DateTime.now();
    final dt = now.difference(last).inMilliseconds / 1000.0;
    last = now;

    final h = MediaQuery.of(context).size.height;
    final speed = config.baseSpeed + engine.score * config.rampPerScore;

    engine.tick(dt: dt, screenH: h, speedPxPerSec: speed);

    if (engine.gameOver) {
      setState(() => phase = GamePhase.gameOver);
    } else {
      setState(() {});
    }
  }

  void start() {
    engine.reset();
    cheat.reset();
    cheatActive = false;
    setState(() => phase = GamePhase.playing);
  }

  Future<void> triggerCheat() async {
    cheatActive = true;
    setState(() {});
    await cheatSeq.run(
      totalMs: 3000,
      onTick: () => mounted ? setState(() {}) : null,
    );
    if (mounted) setState(() => phase = GamePhase.gameOver);
  }

  void tap(TapDownDetails d) {
    if (phase != GamePhase.playing || cheatActive) return;

    cheat.recordTap(now: DateTime.now(), perfectHit: false);
    if (cheat.cheatingDetected) {
      triggerCheat();
      return;
    }

    final w = MediaQuery.of(context).size.width;
    final lane = resolveLane(
      tapX: d.localPosition.dx,
      screenW: w,
      laneCount: config.laneCount,
    );

    engine.handleLaneTapAnywhere(
      lane: lane,
      tapY: d.localPosition.dy,
      maxDistancePx: engine.tileHeight * 0.9,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final snap = engine.snapshot();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: tap,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Stack(
          children: [
            Board(
              laneCount: config.laneCount,
              tiles: snap.tiles,
              cheatSeq: cheatActive ? cheatSeq : null,
              colorMode: cosmetics.multiColorUnlocked
                  ? ColorMode.multi
                  : ColorMode.mono,
            ),

            Hud(
              score: snap.score,
              strikes: snap.strikes,
              maxStrikes: config.maxStrikes,
            ),

            if (phase == GamePhase.idle)
              StartOverlay(onStart: start),

            if (phase == GamePhase.gameOver)
              GameOverOverlay(
                score: snap.score,
                strikes: snap.strikes,
                onRestart: start,
              ),
          ],
        ),
      ),
    );
  }
}
