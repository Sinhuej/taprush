import 'package:flutter/material.dart';
import 'game_loop.dart';
import '../ui/widgets.dart';

class TapRushGame extends StatefulWidget {
  const TapRushGame({super.key});

  @override
  State<TapRushGame> createState() => _TapRushGameState();
}

class _TapRushGameState extends State<TapRushGame>
    with SingleTickerProviderStateMixin {
  late GameLoop game;

  @override
  void initState() {
    super.initState();
    game = GameLoop(this, onUpdate: () => setState(() {}));
  }

  @override
  void dispose() {
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: game.onTap,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1E2E),
        body: SafeArea(
          child: Stack(
            children: [
              ScoreDisplay(score: game.score),
              HitZone(
                top: game.hitZoneTop,
                bottom: game.hitZoneBottom,
              ),
              MovingBar(y: game.barY),
              HitIndicator(
                show: game.showHit,
                success: game.hitSuccess,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
