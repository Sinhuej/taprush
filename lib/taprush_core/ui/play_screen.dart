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

  Offset? _downPos;
  DateTime? _downAt;
  Offset _lastPos = Offset.zero;

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

      if (_humLine != null && _humAt != null) {
        if (DateTime.now().difference(_humAt!).inMilliseconds > 650) {
          _humLine = null;
          _humAt = null;
        }
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
    final res = engine.onGesture(GestureSample(
      startX: start.dx,
      startY: start.dy,
      endX: end.dx,
      endY: end.dy,
      durationMs: durationMs,
    ));

    if (res.hit && res.bomb && res.flicked) {
      // Flick FX
      final dir = Offset(end.dx - start.dx, end.dy - start.dy);
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

    setState(() {});
  }

  Offset _norm(Offset v) {
    final m = sqrt(v.dx * v.dx + v.dy * v.dy);
    if (m < 0.001) return const Offset(1, 0);
    return Offset(v.dx / m, v.dy / m);
  }

  Color _bgColor(int tier) {
    switch (tier) {
      case 0: return const Color(0xFFF6F7FB);
      case 1: return const Color(0xFFEEF7FF);
      case 2: return const Color(0xFFFFF4EA);
      case 3: return const Color(0xFFF4ECFF);
      default: return const Color(0xFFE9FFF2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final geom = LaneGeometry.fromSize(size.width, size.height);
    engine.setGeometry(geom);

    final bg = _bgColor(engine.backgroundTier());
    final over = engine.isGameOver;

    final strikeFlashOpacity = _strikeFlashAt == null
        ? 0.0
        : (1.0 - (DateTime.now().difference(_strikeFlashAt!).inMilliseconds / 140.0))
            .clamp(0.0, 1.0);

    final perfectOpacity = _perfectRingAt == null
        ? 0.0
        : (1.0 - (DateTime.now().difference(_perfectRingAt!).inMilliseconds / 220.0))
            .clamp(0.0, 1.0);

    double flickT = 0.0;
    if (_flickAt != null) {
      flickT = (DateTime.now().difference(_flickAt!).inMilliseconds / 160.0).clamp(0.0, 1.0);
      if (flickT >= 1.0) {
        _flickAt = null;
        _flickStart = null;
        _flickEnd = null;
      }
    }

    final shakeX = _shake == 0 ? 0.0 : (sin(DateTime.now().millisecondsSinceEpoch / 28) * _shake);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,

        // ✅ TAPS (always fire)
        onTapDown: (d) {
          _downPos = d.localPosition;
          _downAt = DateTime.now();
          _lastPos = d.localPosition;
        },
        onTapUp: (d) {
          if (_downPos == null || _downAt == null) return;
          final ms = DateTime.now().difference(_downAt!).inMilliseconds;
          _submitGesture(_downPos!, _downPos!, ms <= 0 ? 1 : ms);
          _downPos = null;
          _downAt = null;
        },

        // ✅ SWIPES (for flicking bombs)
        onPanStart: (d) {
          _downPos = d.localPosition;
          _downAt = DateTime.now();
          _lastPos = d.localPosition;
        },
        onPanUpdate: (d) => _lastPos = d.localPosition,
        onPanEnd: (_) {
          if (_downPos == null || _downAt == null) return;
          final ms = DateTime.now().difference(_downAt!).inMilliseconds;
          _submitGesture(_downPos!, _lastPos, ms <= 0 ? 1 : ms);
          _downPos = null;
          _downAt = null;
        },

        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bg, Color.lerp(bg, Colors.black.withOpacity(0.03), 0.55)!],
            ),
          ),
          child: Stack(
            children: [
              // playfield shake
              Transform.translate(
                offset: Offset(shakeX, 0),
                child: Stack(
                  children: [
                    for (int i = 1; i < kLaneCount; i++)
                      Positioned(
                        left: geom.laneLeft(i),
                        top: 0,
                        bottom: 0,
                        child: Container(width: 1, color: Colors.black.withOpacity(0.075)),
                      ),

                    for (final e in engine.entities)
                      Positioned(
                        left: geom.laneLeft(e.lane) + 6,
                        top: e.dir == FlowDir.down ? e.y + 6 : (e.y - geom.tileHeight) + 6,
                        child: _entityTile(
                          width: geom.laneWidth - 12,
                          height: geom.tileHeight - 12,
                          isBomb: e.isBomb,
                        ),
                      ),
                  ],
                ),
              ),

              // HUD
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

              // humiliation
              if (_humLine != null)
                Positioned(
                  top: 96,
                  left: 12,
                  right: 12,
                  child: _humBanner(_humLine!, _humAt!),
                ),

              // perfect ring
              if (_perfectRingPos != null && perfectOpacity > 0)
                Positioned(
                  left: _perfectRingPos!.dx - 18,
                  top: _perfectRingPos!.dy - 18,
                  child: Opacity(
                    opacity: perfectOpacity,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 2, color: Colors.black.withOpacity(0.55)),
                      ),
                    ),
                  ),
                ),

              // flick bomb fx
              if (_flickAt != null && _flickStart != null && _flickEnd != null)
                Positioned(
                  left: lerpDouble(_flickStart!.dx, _flickEnd!.dx, _easeOut(flickT))! - 12,
                  top: lerpDouble(_flickStart!.dy, _flickEnd!.dy, _easeOut(flickT))! - 12,
                  child: Opacity(
                    opacity: (1.0 - flickT).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: flickT * 6.0,
                      child: const Text('💣', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                ),

              // strike flash
              if (strikeFlashOpacity > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: strikeFlashOpacity * 0.22,
                      child: Container(color: Colors.redAccent),
                    ),
                  ),
                ),

              // game over
              if (over)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.62),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('GAME OVER', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text(
                          'Score: ${engine.stats.score}   •   Coins: ${engine.stats.coins}\nAccuracy: ${(engine.stats.accuracy * 100).round()}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.92), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // bank coins to app state
                            appState.coins += engine.stats.coins;
                            Navigator.of(context).pop();
                          },
                          child: const Text('Back to Menu'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => setState(() => engine.reset(newMode: widget.mode)),
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
    final p = 1.0 - (1.0 - t);
    return 1.0 - pow(1.0 - p, 3).toDouble();
  }

  Widget _entityTile({required double width, required double height, required bool isBomb}) {
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
            colors: [Color(0xFF1A1A1A), Color(0xFF050505)],
          ),
          border: Border.all(color: Colors.redAccent, width: 3),
          boxShadow: [
            BoxShadow(color: Colors.redAccent.withOpacity(0.35), blurRadius: 16),
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 6)),
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
          colors: [Color(0xFF2D2D2D), Color(0xFF0F0F0F)],
        ),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 6))],
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
      ),
      child: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  Widget _humBanner(String text, DateTime at) {
    final ageMs = DateTime.now().difference(at).inMilliseconds.toDouble();
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
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
