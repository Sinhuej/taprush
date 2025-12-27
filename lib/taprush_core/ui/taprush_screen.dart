import 'dart:async';
import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/game_engine.dart';
import '../engine/gesture.dart';

class TapRushScreen extends StatefulWidget {
  const TapRushScreen({super.key});

  @override
  State<TapRushScreen> createState() => _TapRushScreenState();
}

class _TapRushScreenState extends State<TapRushScreen> {
  final TapRushEngine engine = TapRushEngine();

  Timer? _timer;
  DateTime _lastFrame = DateTime.now();

  GameMode _mode = GameMode.normal;

  // Gesture tracking
  Offset? _gestureStart;
  DateTime? _gestureStartTime;

  @override
  void initState() {
    super.initState();
    engine.reset(newMode: _mode);

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final dt =
          now.difference(_lastFrame).inMilliseconds / 1000.0;
      _lastFrame = now;

      engine.tick(dt);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setMode(GameMode m) {
    setState(() {
      _mode = m;
      engine.reset(newMode: _mode);
    });
  }

  void _handlePanStart(DragStartDetails d) {
    _gestureStart = d.localPosition;
    _gestureStartTime = DateTime.now();
  }

  void _handlePanEnd(DragEndDetails d, Offset endPosition) {
    if (_gestureStart == null || _gestureStartTime == null) return;

    final durationMs = DateTime.now()
        .difference(_gestureStartTime!)
        .inMilliseconds;

    final gsample = GestureSample(
      startX: _gestureStart!.dx,
      startY: _gestureStart!.dy,
      endX: endPosition.dx,
      endY: endPosition.dy,
      durationMs: durationMs,
    );

    engine.onGesture(gsample);

    _gestureStart = null;
    _gestureStartTime = null;
  }

  Color _bgColor(int tier) {
    switch (tier) {
      case 0:
        return const Color(0xFFF5F5F5);
      case 1:
        return const Color(0xFFEFF7FF);
      case 2:
        return const Color(0xFFFFF3E6);
      case 3:
        return const Color(0xFFF3E6FF);
      default:
        return const Color(0xFFE6FFF2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final geom = LaneGeometry.fromSize(
      size.width,
      size.height,
    );
    engine.setGeometry(geom);

    final bg = _bgColor(engine.backgroundTier());
    final over = engine.isGameOver;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _handlePanStart,
        onPanUpdate: (_) {}, // ignore continuous drag
        onPanEnd: (d) =>
            _handlePanEnd(d, _gestureStart ?? Offset.zero),
        child: Container(
          color: bg,
          child: Stack(
            children: [
              // Lane dividers
              for (int i = 1; i < kLaneCount; i++)
                Positioned(
                  left: geom.laneLeft(i),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: Colors.black.withOpacity(0.08),
                  ),
                ),

              // Tiles & bombs
              for (final e in engine.entities)
                Positioned(
                  left: geom.laneLeft(e.lane),
                  top: e.dir == FlowDir.down
                      ? e.y
                      : (e.y - geom.tileHeight),
                  child: Container(
                    width: geom.laneWidth,
                    height: geom.tileHeight,
                    decoration: BoxDecoration(
                      color: e.isBomb
                          ? Colors.black
                          : Colors.black87,
                      border: Border.all(
                        width: e.isBomb ? 3 : 1,
                        color: e.isBomb
                            ? Colors.redAccent
                            : Colors.white.withOpacity(0.1),
                      ),
                      boxShadow: e.isBomb
                          ? [
                              BoxShadow(
                                color: Colors.redAccent
                                    .withOpacity(0.4),
                                blurRadius: 12,
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: e.isBomb
                        ? const Text('💣',
                            style: TextStyle(fontSize: 24))
                        : null,
                  ),
                ),

              // HUD
              Positioned(
                top: 44,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    _pill('Score', engine.stats.score),
                    _pill('Coins', engine.stats.coins),
                    _pill(
                        'Strikes',
                        '${engine.stats.strikes}/5'),
                    _pill(
                        'Acc',
                        '${(engine.stats.accuracy * 100).round()}%'),
                  ],
                ),
              ),

              // Mode buttons
              Positioned(
                bottom: 18,
                left: 12,
                right: 12,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: [
                    _modeChip('Normal', GameMode.normal),
                    _modeChip('Reverse', GameMode.reverse),
                    _modeChip('Epic', GameMode.epic),
                  ],
                ),
              ),

              // Game Over overlay
              if (over)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'GAME OVER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Score: ${engine.stats.score}\n'
                          'Coins: ${engine.stats.coins}\n'
                          'Accuracy: ${(engine.stats.accuracy * 100).round()}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              _setMode(_mode),
                          child: const Text('Run it back'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Object value) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _modeChip(String label, GameMode m) {
    final selected = _mode == m;
    return GestureDetector(
      onTap: () => _setMode(m),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(width: 2, color: Colors.black),
          color: selected
              ? Colors.black.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
