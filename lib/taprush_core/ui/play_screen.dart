import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/game_engine.dart';
import '../engine/gesture.dart';
import '../fun/humiliation.dart';

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

  Offset? _startPos;
  Offset? _endPos;
  DateTime? _startTime;

  int _prevStrikes = 0;

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
        _prevStrikes = engine.stats.strikes;
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submitGesture() {
    if (_startPos == null || _startTime == null) return;

    final end = _endPos ?? _startPos!;
    final durationMs =
        DateTime.now().difference(_startTime!).inMilliseconds.clamp(1, 1000);

    engine.onGesture(
      GestureSample(
        startX: _startPos!.dx,
        startY: _startPos!.dy,
        endX: end.dx,
        endY: end.dy,
        durationMs: durationMs,
      ),
    );

    _startPos = null;
    _endPos = null;
    _startTime = null;
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

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          _startPos = e.localPosition;
          _endPos = e.localPosition;
          _startTime = DateTime.now();
        },
        onPointerMove: (e) {
          _endPos = e.localPosition;
        },
        onPointerUp: (_) => _submitGesture(),
        child: Container(
          color: _bgColor(engine.backgroundTier()),
          child: Stack(
            children: [
              for (final e in engine.entities)
                Positioned(
                  left: geom.laneLeft(e.lane),
                  top: e.dir == FlowDir.down
                      ? e.y
                      : e.y - geom.tileHeight,
                  width: geom.laneWidth,
                  height: geom.tileHeight,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: e.isBomb ? Colors.redAccent : Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

              Positioned(
                top: 40,
                left: 20,
                child: Text(
                  'Score ${engine.stats.score}  Lives ${5 - engine.stats.strikes}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
