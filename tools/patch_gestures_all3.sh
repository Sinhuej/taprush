#!/usr/bin/env bash
set -euo pipefail

# --- 1) gesture.dart: mode tuning + flick direction classification ---
cat << 'EOT' > lib/taprush_core/engine/gesture.dart
import 'dart:ui';

enum GestureType {
  tap,
  flick,
  ignore,
}

enum FlickDir {
  up,
  down,
  left,
  right,
  none,
}

class GestureTuning {
  final double flickDistanceSq;
  final double flickVelocityMin;
  final double flickMinDurationMs;
  final double flickPrimaryAxisMin;

  final double tapMaxDurationMs;
  final double tapMaxDistanceSq;

  const GestureTuning({
    required this.flickDistanceSq,
    required this.flickVelocityMin,
    required this.flickMinDurationMs,
    required this.flickPrimaryAxisMin,
    required this.tapMaxDurationMs,
    required this.tapMaxDistanceSq,
  });

  // Default, safe arcade-feel tuning.
  static const GestureTuning normal = GestureTuning(
    flickDistanceSq: 900,      // 30px^2
    flickVelocityMin: 0.70,    // px/ms
    flickMinDurationMs: 25,    // prevent spikes
    flickPrimaryAxisMin: 22,   // directional intent
    tapMaxDurationMs: 160,
    tapMaxDistanceSq: 400,     // 20px^2
  );

  // Epic: allow slightly faster classification (more chaos, still strict).
  static const GestureTuning epic = GestureTuning(
    flickDistanceSq: 900,
    flickVelocityMin: 0.65,
    flickMinDurationMs: 22,
    flickPrimaryAxisMin: 22,
    tapMaxDurationMs: 150,
    tapMaxDistanceSq: 400,
  );

  // Reverse: keep tap strict; flick slightly more deliberate to avoid accidental swipes.
  static const GestureTuning reverse = GestureTuning(
    flickDistanceSq: 1000,     // tiny bit farther
    flickVelocityMin: 0.70,
    flickMinDurationMs: 25,
    flickPrimaryAxisMin: 24,   // stronger intent
    tapMaxDurationMs: 160,
    tapMaxDistanceSq: 380,     // slightly tighter
  );
}

class GestureSample {
  final Offset start;
  final Offset end;
  final Duration startTime;
  final Duration endTime;

  GestureSample({
    required this.start,
    required this.end,
    required this.startTime,
    required this.endTime,
  });

  /// Total gesture duration in milliseconds
  double get durationMs => (endTime - startTime).inMicroseconds / 1000.0;

  /// Delta vector
  Offset get delta => end - start;

  /// Squared distance (cheap, deterministic)
  double get distanceSquared => delta.dx * delta.dx + delta.dy * delta.dy;

  /// Distance in pixels
  double get distance => delta.distance;

  /// Velocity in px/ms
  double get velocity => durationMs <= 0 ? 0 : distance / durationMs;

  /// Primary axis magnitude (prevents jitter flicks)
  double get primaryAxisMagnitude =>
      delta.dx.abs() > delta.dy.abs() ? delta.dx.abs() : delta.dy.abs();

  /// Direction of the swipe (based on dominant axis)
  FlickDir get flickDir {
    final dx = delta.dx;
    final dy = delta.dy;

    if (dx.abs() < 1 && dy.abs() < 1) return FlickDir.none;

    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? FlickDir.right : FlickDir.left;
    } else {
      return dy >= 0 ? FlickDir.down : FlickDir.up;
    }
  }

  /// Canonical gesture classification with tunable thresholds
  GestureType classify({GestureTuning tuning = GestureTuning.normal}) {
    // Flick: fast, far, intentional
    if (durationMs >= tuning.flickMinDurationMs &&
        distanceSquared >= tuning.flickDistanceSq &&
        velocity >= tuning.flickVelocityMin &&
        primaryAxisMagnitude >= tuning.flickPrimaryAxisMin) {
      return GestureType.flick;
    }

    // Tap: quick and still
    if (durationMs <= tuning.tapMaxDurationMs &&
        distanceSquared <= tuning.tapMaxDistanceSq) {
      return GestureType.tap;
    }

    return GestureType.ignore;
  }

  @override
  String toString() {
    return 'GestureSample('
        'durationMs=${durationMs.toStringAsFixed(1)}, '
        'distance=${distance.toStringAsFixed(1)}, '
        'velocity=${velocity.toStringAsFixed(2)}, '
        'dir=$flickDir'
        ')';
  }
}
EOT

# --- 2) play_screen.dart: feed proper GestureSample + lane-aware flick direction gate + debug overlay ---
cat << 'EOT' > lib/taprush_core/ui/play_screen.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

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

  Offset? _downPos;
  Offset? _lastPos;
  int? _downMicros;

  int _prevStrikes = 0;

  // Debug overlay
  String? _debugGesture;
  Timer? _debugTimer;

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
    _debugTimer?.cancel();
    super.dispose();
  }

  GestureTuning _tuningForMode(GameMode mode) {
    switch (mode) {
      case GameMode.epic:
        return GestureTuning.epic;
      case GameMode.reverse:
        return GestureTuning.reverse;
      default:
        return GestureTuning.normal;
    }
  }

  // Lane-aware + mode-aware direction rule:
  // - Normal/Epic: vertical flick DOWN counts as a "valid flick intent"
  // - Reverse: vertical flick UP counts as a "valid flick intent"
  //
  // (We only gate flicks. Taps remain taps.)
  bool _isValidFlickDirectionForMode(FlickDir dir, GameMode mode) {
    if (mode == GameMode.reverse) return dir == FlickDir.up;
    return dir == FlickDir.down;
  }

  void _showDebug(String msg) {
    _debugGesture = msg;
    _debugTimer?.cancel();
    _debugTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _debugGesture = null);
    });
  }

  void _submitGesture(Offset start, Offset end, int startMicros, int endMicros) {
    final sample = GestureSample(
      start: start,
      end: end,
      startTime: Duration(microseconds: startMicros),
      endTime: Duration(microseconds: endMicros),
    );

    final tuning = _tuningForMode(widget.mode);
    final type = sample.classify(tuning: tuning);

    // Direction gate only applies to flick classification
    if (type == GestureType.flick &&
        !_isValidFlickDirectionForMode(sample.flickDir, widget.mode)) {
      _showDebug('IGNORED flick dir=${sample.flickDir}  ${sample.toString()}');
      return;
    }

    _showDebug('${type.toString().split(".").last.toUpperCase()} dir=${sample.flickDir}  ${sample.toString()}');

    engine.onGesture(sample);
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
          _downPos = e.localPosition;
          _lastPos = e.localPosition;
          _downMicros = DateTime.now().microsecondsSinceEpoch;
        },
        onPointerMove: (e) {
          _lastPos = e.localPosition;
        },
        onPointerUp: (e) {
          if (_downPos == null || _downMicros == null) return;
          final endMicros = DateTime.now().microsecondsSinceEpoch;
          _submitGesture(_downPos!, _lastPos ?? _downPos!, _downMicros!, endMicros);
          _downPos = null;
          _downMicros = null;
        },
        child: Container(
          color: _bgColor(engine.backgroundTier()),
          child: Stack(
            children: [
              // 🎮 RENDER TILES
              for (final ent in engine.entities)
                Positioned(
                  left: geom.laneLeft(ent.lane),
                  top: ent.dir == FlowDir.down
                      ? ent.y
                      : ent.y - geom.tileHeight,
                  width: geom.laneWidth,
                  height: geom.tileHeight,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ent.isBomb ? Colors.redAccent : Colors.black,
                      borderRadius: BorderRadius.circular(8),
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

              // Debug overlay (top-right)
              if (_debugGesture != null)
                Positioned(
                  top: 40,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _debugGesture!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
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
EOT

echo "✅ Patch applied: gestures (lane-aware flick dir, per-mode tuning, debug overlay)"
