import 'package:flutter/material.dart';

class GameOverOverlay extends StatelessWidget {
  final int score;
  final int strikes;
  final void Function() onRestart;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.strikes,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Score: $score'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRestart,
            child: const Text('RESTART'),
          ),
        ],
      ),
    );
  }
}
