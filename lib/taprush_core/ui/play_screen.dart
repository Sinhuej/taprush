import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker, TickerProviderStateMixin;

import '../engine/models.dart';
import '../engine/game_engine.dart';
import '../engine/gesture.dart';

class PlayScreen extends StatefulWidget {
  final GameMode mode;
  const PlayScreen({super.key, required this.mode});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with TickerProviderStateMixin {
  final TapRushEngine engine = TapRushEngine();

  Ticker? _ticker;
  Duration _last = Duration.zero;

  Offset? _downPos;
  Offset? _lastPos;
  Duration? _downTime;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((elapsed) {
      if (!_initialized) return;

      if (_last == Duration.zero) {
        _last = elapsed;
        return;
      }

      final dt = (elapsed - _last).inMicroseconds / 1000000.0;
      _last = elapsed;

      // Stop sim on game over (prevents weird “freeze/loop” behavior)
      if (engine.stats.strikes >= 5) {
        if (mounted) setState(() {});
        return;
      }

      engine.tick(dt);
      if (mounted) setState(() {});
    });

    _ticker!.start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _submitGesture(Offset start, Offset end, int durationMs) {
    final endTime = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
    final startTime = endTime - Duration(milliseconds: durationMs.clamp(1, 1000));

    engine.onGesture(
      GestureSample(
        start: start,
        end: end,
        startTime: startTime,
        endTime: endTime,
      ),
    );
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

    if (!_initialized) {
      engine.reset(newMode: widget.mode);
      _initialized = true;
    }

    final gameOver = engine.stats.strikes >= 5;

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          if (gameOver) return;
          _downPos = e.localPosition;
          _lastPos = e.localPosition;
          _downTime = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
        },
        onPointerMove: (e) {
          if (gameOver) return;
          _lastPos = e.localPosition;
        },
        onPointerUp: (e) {
          if (gameOver) return;
          if (_downPos == null || _downTime == null) return;

          final now = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
          final durMs = (now - _downTime!).inMilliseconds.clamp(1, 1000);

          _submitGesture(_downPos!, _lastPos ?? _downPos!, durMs);

          _downPos = null;
          _lastPos = null;
          _downTime = null;
        },
        child: Container(
          color: _bgColor(engine.backgroundTier()),
          child: Stack(
            children: [
              // Tiles
              for (final e in engine.entities)
                Positioned(
                  left: geom.laneLeft(e.lane),
                  top: e.dir == FlowDir.down ? e.y : e.y - geom.tileHeight,
                  width: geom.laneWidth,
                  height: geom.tileHeight,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: e.isBomb ? Colors.transparent : Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      border: e.isBomb ? Border.all(width: 3) : null,
                    ),
                    alignment: Alignment.center,
                    child: e.isBomb
                        ? const Text('💣', style: TextStyle(fontSize: 28))
                        : const SizedBox.shrink(),
                  ),
                ),

              // HUD
              Positioned(
                top: 40,
                left: 20,
                child: Text(
                  'Score ${engine.stats.score}  Lives ${5 - engine.stats.strikes}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              if (gameOver)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                    alignment: Alignment.center,
                    child: const Text(
                      'GAME OVER',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
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
