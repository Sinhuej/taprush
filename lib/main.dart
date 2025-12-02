import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const TapRushApp());
}

/// BRAND COLORS (Option 3 Icon)
class AppColors {
  static const Color deepPurple = Color(0xFF4A1DBA);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color neonPink = Color(0xFFFF2CC3);
  static const Color midnight = Color(0xFF0A0018);
  static const Color barYellow = Color(0xFFFFD028);
}

class TapRushApp extends StatelessWidget {
  const TapRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapRush',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.midnight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const TapRushGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TapRushGame extends StatefulWidget {
  const TapRushGame({super.key});

  @override
  State<TapRushGame> createState() => _TapRushGameState();
}

class FallingBar {
  double y = -1.0;
  double speed = 0.01;
  Color color;

  FallingBar(this.color);
}

class _TapRushGameState extends State<TapRushGame> {
  final Random random = Random();

  List<FallingBar> bars = [];
  int score = 0;
  int lives = 3;

  bool gameRunning = false;
  Timer? gameLoopTimer;

  /// Frequency of bar spawning
  Duration spawnRate = const Duration(milliseconds: 900);
  Timer? spawnTimer;

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    spawnTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    bars.clear();
    score = 0;
    lives = 3;
    gameRunning = true;

    // GAME LOOP TICK
    gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateBars();
    });

    // BAR SPAWNER
    spawnTimer = Timer.periodic(spawnRate, (timer) {
      spawnBar();
    });

    setState(() {});
  }

  void endGame() {
    gameRunning = false;
    gameLoopTimer?.cancel();
    spawnTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.deepPurple,
          title: const Text(
            "Game Over",
            style: TextStyle(color: Colors.white, fontSize: 28),
          ),
          content: Text(
            "Score: $score",
            style: const TextStyle(color: Colors.white70, fontSize: 22),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
              child: const Text(
                "Play Again",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        );
      },
    );
  }

  void spawnBar() {
    List<Color> colors = [
      AppColors.neonBlue,
      AppColors.neonPink,
      AppColors.barYellow,
    ];

    bars.add(FallingBar(colors[random.nextInt(colors.length)]));
  }

  void updateBars() {
    setState(() {
      for (var bar in bars) {
        bar.y += bar.speed;
      }

      // Remove bars that passed bottom
      bars.removeWhere((bar) {
        if (bar.y > 1.2) {
          lives--;
          if (lives <= 0) {
            endGame();
          }
          return true;
        }
        return false;
      });
    });
  }

  void tapBar(FallingBar bar) {
    setState(() {
      score++;
      bars.remove(bar);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Glow
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.midnight,
                  AppColors.deepPurple.withOpacity(0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Score & Lives Display
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Score: $score",
                    style: const TextStyle(fontSize: 26, color: Colors.white),
                  ),
                  Text(
                    "Lives: $lives",
                    style: const TextStyle(fontSize: 26, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Game Bars
          ...bars.map((bar) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 16),
              top: MediaQuery.of(context).size.height * bar.y,
              left: 20,
              right: 20,
              height: 50,
              child: GestureDetector(
                onTap: () => tapBar(bar),
                child: Container(
                  decoration: BoxDecoration(
                    color: bar.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: bar.color.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 4,
                      )
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          // Start Button
          if (!gameRunning)
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: startGame,
                child: const Text(
                  "START TAPRUSH",
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
