#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Fixing TapRush gameplay issues..."

########################################
# STEP 1 — Fix bomb rendering in tiles
########################################
cat > lib/taprush_core/ui/play_screen.dart <<'EOF'
import 'dart:async';
import 'dart:math';

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

  FlickFx? _flickFx;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final dt = now.difference(_lastFrame).inMilliseconds / 1000.0;
      _lastFrame = now;

      engine.tick(dt);

      if (_flickFx != null) {
        _flickFx!.advance(dt);
        if (_flickFx!.done) {
          _flickFx = null;
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

  void _submitGesture(Offset start, Offset end, int durationMs) {
    final endTime =
        Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
    final startTime = endTime - Duration(milliseconds: durationMs);

    final res = engine.onGesture(
      GestureSample(
        start: start,
        end: end,
        startTime: startTime,
        endTime: endTime,
      ),
    );

    if (res.hit && res.bomb && res.flicked) {
      final dir = end - start;
      final n = dir / max(1, dir.distance);
      _flickFx = FlickFx(start: start, end: start + n * 160);
    }
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
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: e.isBomb
                      ? const Center(
                          child: Text('💣',
                              style: TextStyle(fontSize: 26)),
                        )
                      : null,
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

            if (engine.isGameOver)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GAME OVER',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          engine.reset(newMode: widget.mode);
                        });
                      },
                      child: const Text('Restart'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
EOF

########################################
# STEP 2 — Fix tap forgiveness
########################################
cat > lib/taprush_core/engine/models.dart <<'EOF'
import 'dart:math';

const int kLaneCount = 6;

enum FlowDir { down, up }
enum GameMode { normal, reverse, epic }
enum HitGrade { perfect, good, miss }

class LaneGeometry {
  final double width;
  final double height;
  final double laneWidth;
  final double tileHeight;

  LaneGeometry({
    required this.width,
    required this.height,
    required this.laneWidth,
    required this.tileHeight,
  });

  static LaneGeometry fromSize(double w, double h) {
    return LaneGeometry(
      width: w,
      height: h,
      laneWidth: w / kLaneCount,
      tileHeight: 80,
    );
  }

  double laneLeft(int lane) => lane * laneWidth;

  double centerY(TapEntity e) =>
      e.dir == FlowDir.down ? e.y + tileHeight / 2 : e.y - tileHeight / 2;
}

class TapEntity {
  final String id;
  final int lane;
  final FlowDir dir;
  final bool isBomb;
  double y;
  bool consumed = false;

  TapEntity({
    required this.id,
    required this.lane,
    required this.dir,
    required this.isBomb,
    required this.y,
  });

  bool isMissed(LaneGeometry g) {
    return dir == FlowDir.down
        ? y > g.height
        : y + g.tileHeight < 0;
  }

  bool containsTap(LaneGeometry g, double x, double yTap) {
    if (consumed) return false;

    const double slop = 12;

    final left = g.laneLeft(lane) - slop;
    final right = left + g.laneWidth + slop * 2;

    final top = dir == FlowDir.down ? y : y - g.tileHeight;
    final bottom = top + g.tileHeight;

    return x >= left &&
        x <= right &&
        yTap >= top - slop &&
        yTap <= bottom + slop;
  }
}

class RunStats {
  int score = 0;
  int coins = 0;
  int strikes = 0;
  int totalHits = 0;
  int perfectHits = 0;
  int bombsFlicked = 0;
  int bonusLivesEarned = 0;

  void onPerfect({int coinMult = 1}) {
    score += 2 * coinMult;
    coins += 1 * coinMult;
    totalHits++;
    perfectHits++;
  }

  void onGood({int coinMult = 1}) {
    score += 1 * coinMult;
    coins += 1 * coinMult;
    totalHits++;
  }

  void onStrike() {
    strikes++;
  }
}
EOF

########################################
# STEP 3 — Enforce no double scoring
########################################
grep -q "consumed = true" lib/taprush_core/engine/game_engine.dart || \
sed -i '/entities.remove(target);/a\ \ \ \ target.consumed = true;' \
lib/taprush_core/engine/game_engine.dart

echo "✅ TapRush gameplay fixes applied successfully."
