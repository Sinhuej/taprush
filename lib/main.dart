import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const TapRushApp());

class TapRushApp extends StatelessWidget {
  const TapRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TapRushGame(),
    );
  }
}

class TapRushGame extends StatefulWidget {
  const TapRushGame({super.key});

  @override
  State<TapRushGame> createState() => _TapRushGameState();
}

class _TapRushGameState extends State<TapRushGame>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  double barY = -150;
  double barSpeed = 0.7; // slow and consistent
  int score = 0;
  bool showHit = false;
  bool hitSuccess = false;

  // Target "hit zone"
  final double hitZoneTop = 350;
  final double hitZoneBottom = 450;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    )..addListener(gameLoop);

    controller.repeat();
  }

  void gameLoop() {
    setState(() {
      barY += barSpeed * 10;

      if (barY > 900) {
        barY = -Random().nextInt(400);
        showHit = false;
      }
    });
  }

  void onTap() {
    final bool inside =
        (barY + 100 > hitZoneTop && barY < hitZoneBottom);

    setState(() {
      showHit = true;
      hitSuccess = inside;

      if (inside) score++;
      else score = max(score - 1, 0);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1E2E),
        body: SafeArea(
          child: Stack(
            children: [
              // Score
              Positioned(
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
              ),

              // Target Hit Zone
              Positioned(
                top: hitZoneTop,
                left: 0,
                right: 0,
                child: Container(
                  height: hitZoneBottom - hitZoneTop,
                  color: Colors.white24,
                ),
              ),

              // Moving Bar
              Positioned(
                top: barY,
                left: 50,
                right: 50,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              // Hit/Miss indicator
              if (showHit)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: hitSuccess
                          ? Colors.green.withOpacity(0.8)
                          : Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      hitSuccess ? "HIT!" : "MISS",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
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
