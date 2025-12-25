import 'package:flutter/material.dart';
import '../game/input_mode.dart';

class Hud extends StatelessWidget {
  final int score;
  final int best;
  final int strikes;
  final int stage;
  final double speed;
  final int coins;

  final String modeLabel;

  final InputMode inputMode;
  final VoidCallback onToggleInputMode;
  final VoidCallback onOpenBackgrounds;
  final VoidCallback onOpenSkins;
  final VoidCallback onOpenModes;

  const Hud({
    super.key,
    required this.score,
    required this.best,
    required this.strikes,
    required this.stage,
    required this.speed,
    required this.coins,
    required this.modeLabel,
    required this.inputMode,
    required this.onToggleInputMode,
    required this.onOpenBackgrounds,
    required this.onOpenSkins,
    required this.onOpenModes,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Text('Mode $modeLabel', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Text('Score $score'),
            const SizedBox(width: 10),
            Text('Best $best'),
            const SizedBox(width: 10),
            Text('Coins $coins'),
            const Spacer(),
            Text('Strikes $strikes'),
            const SizedBox(width: 10),
            Text('Stage $stage'),
            const SizedBox(width: 10),
            Text('Speed ${speed.toStringAsFixed(0)}'),
            IconButton(
              tooltip: 'Modes',
              onPressed: onOpenModes,
              icon: const Icon(Icons.sports_esports),
            ),
            IconButton(
              tooltip: 'Skins',
              onPressed: onOpenSkins,
              icon: const Icon(Icons.palette),
            ),
            IconButton(
              tooltip: 'Backgrounds',
              onPressed: onOpenBackgrounds,
              icon: const Icon(Icons.wallpaper),
            ),
            IconButton(
              tooltip: inputMode == InputMode.laneTap ? 'Input: Lane Tap' : 'Input: Anywhere Tap',
              onPressed: onToggleInputMode,
              icon: Icon(inputMode == InputMode.laneTap ? Icons.touch_app : Icons.pan_tool_alt),
            ),
          ],
        ),
      ),
    );
  }
}
