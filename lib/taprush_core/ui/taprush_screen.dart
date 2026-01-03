import 'dart:ui' show lerpDouble;
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/game_engine.dart';
import '../engine/gesture.dart';
import '../fun/humiliation.dart';
import 'fx_models.dart';

class TapRushScreen extends StatefulWidget {
  const TapRushScreen({super.key});

  @override
  State<TapRushScreen> createState() => _TapRushScreenState();
}

class _TapRushScreenState extends State<TapRushScreen> {
  final TapRushEngine engine = TapRushEngine();
  final HumiliationEngine hum = HumiliationEngine();

  Timer? _timer;
  DateTime _lastFrame = DateTime.now();

  GameMode _mode = GameMode.normal;

  // Gesture tracking
  Offset? _gestureStart;
  DateTime? _gestureStartTime;
  Offset _lastPanPos = Offset.zero;

  // FX state
  FlickFx? _flickFx;
  Offset? _perfectRingPos;
  DateTime? _perfectRingAt;

  DateTime? _strikeFlashAt;
  double _shake = 0.0;

  TextFx? _humText;

  int _prevStrikes = 0;

  @override
  void initState() {
    super.initState();
    engine.reset(newMode: _mode);

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final dt = now.difference(_lastFrame).inMilliseconds / 1000.0;
      _lastFrame = now;

      engine.tick(dt);

      // Detect strikes that happen from misses (engine tick) or tapped bombs
      if (engine.stats.strikes > _prevStrikes) {
        _onStrike();
      }
      _prevStrikes = engine.stats.strikes;

      // Decay shake
      _shake *= 0.86;
      if (_shake.abs() < 0.2) _shake = 0.0;

      // Expire text fx
      if (_humText != null && _humText!.ageMs() > 650) {
        _humText = null;
      }

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
      _prevStrikes = 0;
      _humText = null;
      _flickFx = null;
      _perfectRingPos = null;
      _perfectRingAt = null;
      _strikeFlashAt = null;
      _shake = 0;
    });
  }

  void _onStrike() {
    _strikeFlashAt = DateTime.now();
    _shake = 10.0;

    // Humiliation line (light, non-blocking)
    _humText = TextFx(hum.strikeLine());
  }

  void _onGameOver() {
    _humText = TextFx(hum.gameOverLine());
  }

  void _handlePanStart(DragStartDetails d) {
    _gestureStart = d.localPosition;
    _gestureStartTime = DateTime.now();
    _lastPanPos = d.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    _lastPanPos = d.localPosition;
  }

  void _handlePanEnd(DragEndDetails d) {
    if (_gestureStart == null || _gestureStartTime == null) return;

    final durationMs =
        DateTime.now().difference(_gestureStartTime!).inMilliseconds;

    final gsample = GestureSample(
      start: Offset( _gestureStart!.dx,
      , _gestureStart!.dy,
      final now =
          Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
      final startTime =
          now - Duration(milliseconds: panDurationMs.clamp(1, 1000));

      final sample = GestureSample(
        start: _gestureStart!,
        end: _lastPanPos,
        startTime: startTime,
        endTime: now,
      );

      final dir = sample.end - sample.start;

      _engine.onGesture(sample);

    // FX: flick bomb throw
    if (res.hit && res.bomb && res.flicked) {
      final dir = Offset(gsample.endX - gsample.startX, gsample.endY - gsample.startY);
      final n = _norm(dir);
      final throwDist = 160.0;
      final end = _gestureStart! + n * throwDist;
      _flickFx = FlickFx(start: _gestureStart!, end: end);
    }

    // FX: perfect ring ping
    if (res.hit && !res.bomb && res.grade == HitGrade.perfect) {
      _perfectRingPos = _gestureStart;
      _perfectRingAt = DateTime.now();
    }

    // Game over line on transition to game over
    if (engine.isGameOver) {
      _onGameOver();
    }

    _gestureStart = null;
    _gestureStartTime = null;

    setState(() {});
  }

  Offset _norm(Offset v) {
    final m = sqrt(v.dx * v.dx + v.dy * v.dy);
    if (m < 0.0001) return const Offset(1, 0);
    return Offset(v.dx / m, v.dy / m);
  }

  Color _bgColor(int tier) {
    switch (tier) {
      case 0:
        return const Color(0xFFF6F7FB);
      case 1:
        return const Color(0xFFEEF7FF);
      case 2:
        return const Color(0xFFFFF4EA);
      case 3:
        return const Color(0xFFF4ECFF);
      default:
        return const Color(0xFFE9FFF2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final geom = LaneGeometry.fromSize(size.width, size.height);
    engine.setGeometry(geom);

    final bg = _bgColor(engine.backgroundTier());
    final over = engine.isGameOver;

    final shakeX = _shake == 0 ? 0.0 : (sin(DateTime.now().millisecondsSinceEpoch / 28) * _shake);

    final strikeFlashOpacity = _strikeFlashAt == null
        ? 0.0
        : (1.0 -
                (DateTime.now()
                        .difference(_strikeFlashAt!)
                        .inMilliseconds /
                    140.0))
            .clamp(0.0, 1.0);

    final perfectRingOpacity = _perfectRingAt == null
        ? 0.0
        : (1.0 -
                (DateTime.now()
                        .difference(_perfectRingAt!)
                        .inMilliseconds /
                    220.0))
            .clamp(0.0, 1.0);

    // Flick FX progress
    final flick = _flickFx;
    double flickT = 0.0;
    if (flick != null) {
      flickT = (flick.ageMs() / 160.0).clamp(0.0, 1.0);
      if (flickT >= 1.0) _flickFx = null;
    }

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                bg,
                Color.lerp(bg, Colors.black.withOpacity(0.03), 0.55)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              // subtle vignette
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.1,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.06),
                      ],
                    ),
                  ),
                ),
              ),

              // Apply shake to the playfield only
              Transform.translate(
                offset: Offset(shakeX, 0),
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
                          color: Colors.black.withOpacity(0.075),
                        ),
                      ),

                    // Entities
                    for (final e in engine.entities)
                      Positioned(
                        left: geom.laneLeft(e.lane) + 6,
                        top: e.dir == FlowDir.down
                            ? e.y + 6
                            : (e.y - geom.tileHeight) + 6,
                        child: _entityTile(
                          width: geom.laneWidth - 12,
                          height: geom.tileHeight - 12,
                          isBomb: e.isBomb,
                        ),
                      ),
                  ],
                ),
              ),

              // Perfect ring ping
              if (_perfectRingPos != null && perfectRingOpacity > 0.0)
                Positioned(
                  left: _perfectRingPos!.dx - 18,
                  top: _perfectRingPos!.dy - 18,
                  child: Opacity(
                    opacity: perfectRingOpacity,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                    ),
                  ),
                ),

              // Flick bomb throw FX (little bomb flying)
              if (flick != null)
                Positioned(
                  left: lerpDouble(flick.start.dx, flick.end.dx, _easeOut(flickT))! - 12,
                  top: lerpDouble(flick.start.dy, flick.end.dy, _easeOut(flickT))! - 12,
                  child: Opacity(
                    opacity: (1.0 - flickT).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: flickT * 6.0,
                      child: const Text('💣', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                ),

              // HUD (clean pills)
              Positioned(
                top: 44,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _pill('Score', engine.stats.score),
                    _pill('Coins', engine.stats.coins),
                    _pill('Strikes', '${engine.stats.strikes}/5'),
                    _pill('Acc', '${(engine.stats.accuracy * 100).round()}%'),
                  ],
                ),
              ),

              // Humiliation text (non-blocking)
              if (_humText != null)
                Positioned(
                  top: 96,
                  left: 12,
                  right: 12,
                  child: _humBanner(_humText!.text, _humText!.ageMs()),
                ),

              // Mode chips (for now — we’ll gate later)
              Positioned(
                bottom: 18,
                left: 12,
                right: 12,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _modeChip('Normal', GameMode.normal),
                    _modeChip('Reverse', GameMode.reverse),
                    _modeChip('Epic', GameMode.epic),
                  ],
                ),
              ),

              // Strike flash overlay
              if (strikeFlashOpacity > 0.0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: strikeFlashOpacity * 0.22,
                      child: Container(color: Colors.redAccent),
                    ),
                  ),
                ),

              // Game Over overlay
              if (over)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.62),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'GAME OVER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Score: ${engine.stats.score}   •   Coins: ${engine.stats.coins}\n'
                          'Accuracy: ${(engine.stats.accuracy * 100).round()}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _setMode(_mode),
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

  static double _easeOut(double t) {
    // cubic ease out
    final p = 1.0 - (1.0 - t);
    return 1.0 - pow(1.0 - p, 3).toDouble();
  }

  Widget _entityTile({
    required double width,
    required double height,
    required bool isBomb,
  }) {
    final r = BorderRadius.circular(14);

    if (isBomb) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF050505),
            ],
          ),
          border: Border.all(color: Colors.redAccent, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text('💣', style: TextStyle(fontSize: 24)),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2D2D2D),
            Color(0xFF0F0F0F),
          ],
        ),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Object value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _humBanner(String text, double ageMs) {
    final t = (ageMs / 650.0).clamp(0.0, 1.0);
    final opacity = (t < 0.15 ? (t / 0.15) : (1.0 - (t - 0.15) / 0.85)).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, GameMode m) {
    final selected = _mode == m;
    return GestureDetector(
      onTap: () => _setMode(m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(width: 2, color: Colors.black),
          color: selected ? Colors.black.withOpacity(0.12) : Colors.white.withOpacity(0.28),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
