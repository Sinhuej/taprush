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
  static const Color barYellow = Color(0xFFFFD028); // power-up
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

class FallingBar {
  double y;
  double speed;
  final Color color;
  final bool isPowerUp;

  FallingBar({
    required this.color,
    required this.speed,
    required this.isPowerUp,
    this.y = -1.1,
  });
}

class TapRushGame extends StatefulWidget {
  const TapRushGame({super.key});

  @override
  State<TapRushGame> createState() => _TapRushGameState();
}

class _TapRushGameState extends State<TapRushGame> {
  final Random random = Random();

  final int maxLives = 5;
  final double baseSpeed = 0.012;

  List<FallingBar> bars = [];
  int score = 0;
  int lives = 3;
  int combo = 0;

  bool gameRunning = false;

  Timer? gameLoopTimer;
  Timer? spawnTimer;

  double speedMultiplier = 1.0;
  Duration spawnRate = const Duration(milliseconds: 900);

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
    combo = 0;
    speedMultiplier = 1.0;
    spawnRate = const Duration(milliseconds: 900);
    gameRunning = true;

    gameLoopTimer?.cancel();
    spawnTimer?.cancel();

    // Physics step
    gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => updateBars(),
    );

    // Spawner
    spawnTimer = Timer.periodic(spawnRate, (_) => spawnBar());

    setState(() {});
  }

  void endGame() {
    gameRunning = false;
    gameLoopTimer?.cancel();
    spawnTimer?.cancel();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.deepPurple,
          title: const Text(
            'Game Over',
            style: TextStyle(color: Colors.white, fontSize: 28),
          ),
          content: Text(
            'Score: $score',
            style: const TextStyle(color: Colors.white70, fontSize: 22),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
              child: const Text(
                'Play Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void updateDifficulty() {
    // Simple difficulty curve based on score
    double difficulty;
    if (score < 15) {
      difficulty = 1.0;
    } else if (score < 35) {
      difficulty = 1.4;
    } else if (score < 60) {
      difficulty = 1.8;
    } else {
      difficulty = 2.2;
    }

    speedMultiplier = difficulty;

    // Adjust spawn rate (faster spawns as score climbs)
    int baseMs = 900;
    int newMs = (baseMs ~/ difficulty).clamp(280, 900);
    spawnRate = Duration(milliseconds: newMs);

    spawnTimer?.cancel();
    spawnTimer = Timer.periodic(spawnRate, (_) => spawnBar());
  }

  void spawnBar() {
    // 1 in 6 chance of a power-up bar
    bool isPowerUp = random.nextDouble() < 0.17;

    List<Color> normalColors = [
      AppColors.neonBlue,
      AppColors.neonPink,
    ];

    Color barColor = isPowerUp
        ? AppColors.barYellow
        : normalColors[random.nextInt(normalColors.length)];

    double speed = baseSpeed + random.nextDouble() * 0.006;

    bars.add(
      FallingBar(
        color: barColor,
        speed: speed,
        isPowerUp: isPowerUp,
      ),
    );
  }

  void updateBars() {
    if (!mounted || !gameRunning) {
      return;
    }

    setState(() {
      for (final bar in bars) {
        bar.y += bar.speed * speedMultiplier;
      }

      // Bars that fall past the bottom
      bars.removeWhere((bar) {
        if (bar.y > 1.2) {
          combo = 0; // break combo
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
    if (!gameRunning) return;

    setState(() {
      if (bar.isPowerUp) {
        // Power-up: clear screen + gain life
        bars.clear();
        lives = (lives + 1).clamp(0, maxLives);
        combo += 1;
        score += 3; // bonus for power-up
      } else {
        combo += 1;
        int bonus = combo ~/ 5; // +1 every 5 combo
        score += 1 + bonus;
      }

      bars.remove(bar);
      updateDifficulty();
    });
  }

  Widget buildTopHud() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Score',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            // Combo in the middle
            if (combo >= 3)
              Column(
                children: [
                  const Text(
                    'Combo',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    'x$combo',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonPink,
                    ),
                  ),
                ],
              ),
            // Lives
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Lives',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(maxLives, (index) {
                    bool filled = index < lives;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.favorite,
                        size: 20,
                        color: filled ? AppColors.neonPink : Colors.white24,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBars(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: bars.map((bar) {
        double top = screenHeight * bar.y;

        return Positioned(
          top: top,
          left: 24,
          right: 24,
          height: 52,
          child: GestureDetector(
            onTap: () => tapBar(bar),
            child: Container(
              decoration: BoxDecoration(
                color: bar.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: bar.color.withOpacity(0.6),
                    blurRadius: 24,
                    spreadRadius: 5,
                  ),
                ],
                border: bar.isPowerUp
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              alignment: Alignment.center,
              child: bar.isPowerUp
                  ? const Text(
                      '+ LIFE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildStartOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TapRush',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the falling bars before they\nhit the bottom. Don\'t miss!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepPurple,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: startGame,
            child: const Text(
              'START TAPRUSH',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.midnight,
                  AppColors.deepPurple.withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Bars
          buildBars(context),

          // HUD
          buildTopHud(),

          // Start overlay
          if (!gameRunning) buildStartOverlay(),
        ],
      ),
    );
  }
}

