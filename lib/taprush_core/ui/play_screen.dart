import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/game_engine.dart';
import '../engine/gesture.dart';
import '../fun/humiliation.dart';
import '../app/app_state.dart';

class PlayScreen extends StatefulWidget {
  final GameMode mode;
  const PlayScreen({super.key, required this.mode});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final TapRushEngine engine = TapRushEngine();
  final HumiliationEngine hum = HumiliationEngine();

  Timer? _timer;
  DateTime _lastFrame = DateTime.now();

  // RAW POINTER STATE
  Offset? _downPos;
  Offset? _lastPos;
  DateTime? _downTime;

  int _prevStrikes = 0;

  String? _humLine;
  DateTime? _humAt;

  DateTime? _strikeFlashAt;
  double _shake = 0;

  Offset? _perfectRingPos;
  DateTime? _perfectRingAt;

  Offset? _flickStart;
  Offset? _flickEnd;
  DateTime? _flickAt;

  @override
  void initState() {
    super.initState();
    engine.reset(newMode: widget.mode);

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final dt = now.difference(_lastFrame).inMilliseconds / 1000.0;
      _lastFrame = now;

      engine.tick(dt);

      if (engine.stats.strikes > _prevStrikes) {
        _onStrike();
      }
      _prevStrikes = engine.stats.strikes;

      _shake *= 0.86;
      if (_shake.abs() < 0.2) _shake = 0;

      if (_humLine != null &&
          DateTime.now().difference(_humAt!).inMilliseconds > 650) {
        _humLine = null;
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onStrike() {
    _strikeFlashAt = DateTime.now();
    _shake = 10.0;
    _humLine = hum.strikeLine();
    _humAt = DateTime.now();
  }

  void _onGameOver() {
    _humLine = hum.gameOverLine();
    _humAt = DateTime.now();
  }

  void _submitGesture(Offset start, Offset end, int durationMs) {
    final res = engine.onGesture(
      GestureSample(
        startX: start.dx,
        startY: start.dy,
        endX: end.dx,
        endY: end.dy,
        durationMs: durationMs,
      ),
    );

    if (res.hit && res.bomb && res.flicked) {
      final dir = end - start;
      final n = _norm(dir);
      _flickStart = start;
      _flickEnd = start + n * 160;
      _flickAt = DateTime.now();
    }

    if (res.hit && !res.bomb && res.grade == HitGrade.perfect) {
      _perfectRingPos = start;
      _perfectRingAt = DateTime.now();
    }

    if (engine.isGameOver) _onGameOver();
  }

  Offset _norm(Offset v) {
    final m = sqrt(v.dx * v.dx + v.dy * v.dy);
    if (m < 0.001) return const Offset(1, 0);
    return Offset(v.dx / m, v.dy / m);
  }

  Color _bgColor(int tier) {
    if (tier < 1) return const Color(0xFFF6F7FB);
    if (tier < 2) return const Color(0xFFEEF7FF);
    if (tier < 3) return const Color(0xFFFFF4EA);
    if (tier < 4) return const Color(0xFFF4ECFF);
    return const Color(0xFFE9FFF2);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final geom = LaneGeometry.fromSize(size.width, size.height);
    engine.setGeometry(geom);

    final bg = _bgColor(engine.backgroundTier());
    final over = engine.isGameOver;

    double flickT = 0;
    if (_flickAt != null) {
      flickT = (DateTime.now().difference(_flickAt!).inMilliseconds / 160)
          .clamp(0.0, 1.0);
      if (flickT >= 1) _flickAt = null;
    }

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.opaque,

        onPointerDown: (e) {
          _downPos = e.localPosition;
          _lastPos = e.localPosition;
          _downTime = DateTime.now();
        },

        onPointerMove: (e) {
          _lastPos = e.localPosition;
        },

        onPointerUp: (e) {
          if (_downPos == null || _downTime == null) return;
          final dur =
              DateTime.now().difference(_downTime!).inMilliseconds.clamp(1, 1000);
          _submitGesture(_downPos!, _lastPos ?? _downPos!, dur);
          _downPos = null;
          _downTime = null;
        },

        child: Container(
          color: bg,
          child: Stack(
            children: [
              // (Rendering code unchanged)
            ],
          ),
        ),
      ),
    );
  }
}
