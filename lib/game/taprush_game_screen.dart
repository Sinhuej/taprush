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
