import 'package:flutter/material.dart';

class GameOverOverlay extends StatelessWidget {
  final int score;
  final int strikes;
  final VoidCallback onRestart;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.strikes,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.82),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
              color: Colors.white.withOpacity(0.10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Game Over',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Score: $score'),
                Text('Strikes: $strikes'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRestart,
                  child: const Text('Play Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
