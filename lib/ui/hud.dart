import 'package:flutter/material.dart';

class Hud extends StatelessWidget {
  final int score;
  final int strikes;
  final int maxStrikes;

  const Hud({
    super.key,
    required this.score,
    required this.strikes,
    required this.maxStrikes,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SCORE $score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('STRIKES $strikes/$maxStrikes', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
