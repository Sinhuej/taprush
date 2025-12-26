import 'package:flutter/material.dart';

class StartOverlay extends StatelessWidget {
  final VoidCallback onStart;

  const StartOverlay({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.78),
        child: Center(
          child: GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white24),
                color: Colors.white.withOpacity(0.10),
              ),
              child: const Text(
                'Tap to Start',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
