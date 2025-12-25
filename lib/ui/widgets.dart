import 'package:flutter/material.dart';

class ScoreDisplay extends StatelessWidget {
  final int score;
  const ScoreDisplay({required this.score, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          "SCORE: $score",
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class HitZone extends StatelessWidget {
  final double top;
  final double bottom;

  const HitZone({required this.top, required this.bottom, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Container(
        height: bottom - top,
        color: Colors.white24,
      ),
    );
  }
}

class MovingBar extends StatelessWidget {
  final double y;
  const MovingBar({required this.y, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: y,
      left: 50,
      right: 50,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.deepPurpleAccent,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class HitIndicator extends StatelessWidget {
  final bool show;
  final bool success;

  const HitIndicator({required this.show, required this.success, super.key});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: success
              ? Colors.green.withOpacity(0.8)
              : Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          success ? "HIT!" : "MISS",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
