import 'dart:math';
import 'package:flutter/material.dart';

class GameLoop {
  late final AnimationController controller;
  final VoidCallback onUpdate;

  double barY = -150;
  double barSpeed = 0.7;
  int score = 0;

  bool showHit = false;
  bool hitSuccess = false;

  final double hitZoneTop = 350;
  final double hitZoneBottom = 450;

  GameLoop(TickerProvider vsync, {required this.onUpdate}) {
    controller = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: vsync,
    )..addListener(_loop);

    controller.repeat();
  }

  void _loop() {
    barY += barSpeed * 10;

    if (barY > 900) {
      barY = -Random().nextInt(400).toDouble();
      showHit = false;
    }

    onUpdate();
  }

  void onTap() {
    final inside =
        (barY + 100 > hitZoneTop && barY < hitZoneBottom);

    showHit = true;
    hitSuccess = inside;

    if (inside) {
      score++;
    } else {
      score = max(score - 1, 0);
    }

    onUpdate();
  }

  void dispose() {
    controller.dispose();
  }
}
