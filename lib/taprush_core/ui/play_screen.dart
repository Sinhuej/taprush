import 'dart:async';
import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/game_engine.dart';
import '../engine/gesture.dart';

class PlayScreen extends StatefulWidget {
  final GameMode mode;
  const PlayScreen({super.key, required this.mode});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final TapRushEngine engine = TapRushEngine();

  Timer? _timer;
  DateTime _lastFrame = DateTime.now();

  Offset? _downPos;
  Offset? _lastPos;
  DateTime? _downTime;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _startLoop();
  }

  void _startLoop() {
    _timer?.cancel();
    _lastFrame = DateTime.now();

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (engine.isGameOver) return;

      final now = DateTime.now();
      final dt = now.difference(_lastFrame).inMilliseconds / 1000.0;
      _lastFrame = now;

      engine.tick(dt);
      if (mounted) setState(() {});
    });
  }

  void _restartGame() {
    setState(() {
      engine.reset(newMode: widget.mode);
      _downPos = null;
      _lastPos = null;
      _downTime = null;
      _lastFrame = DateTime.now();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submitGesture(Offset start, Offset end, int durationMs) {
    final endTime =
        Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
    final startTime = endTime - Duration(milliseconds: durationMs);

    engine.onGesture(
      GestureSample(
        start: start,
        end: end,
        startTime: startTime,
        endTime: endTime,
      ),
    );
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

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: engine.isGameOver
            ? null
            : (e) {
                _downPos = e.localPosition;
                _lastPos = e.localPosition;
                _downTime = DateTime.now();
              },
        onPointerMove:
            engine.isGameOver ? null : (e) => _lastPos = e.localPosition,
        onPointerUp: engine.isGameOver
            ? null
            : (e) {
                if (_downPos == null || _downTime == null) return;
                final dur = DateTime.now()
                    .difference(_downTime!)
                    .inMilliseconds
                    .clamp(1, 1000);
                _submitGesture(_downPos!, _lastPos ?? _downPos!, dur);
                _downPos = null;
                _downTime = null;
              },
        child: Stack(
          children: [
            // 🎮 Tiles
            for (final e in engine.entities)
              Positioned(
                left: geom.laneLeft(e.lane),
                top: e.dir == FlowDir.down
                    ? e.y
                    : e.y - geom.tileHeight,
                width: geom.laneWidth,
                height: geom.tileHeight,
                child: Center(
                  child: e.isBomb
                      ? const Text('💣', style: TextStyle(fontSize: 28))
                      : Container(
                          width: geom.laneWidth - 12,
                          height: geom.tileHeight - 12,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                ),
              ),

            // HUD
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

            // 🟥 GAME OVER + RESTART
            if (engine.isGameOver)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          fontSize: 42,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _restartGame,
                        child: const Text(
                          'RESTART',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
