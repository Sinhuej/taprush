import 'package:flutter/material.dart';

class StartOverlay extends StatelessWidget {
  final VoidCallback onStart;

  const StartOverlay({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'Tap to Start',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
