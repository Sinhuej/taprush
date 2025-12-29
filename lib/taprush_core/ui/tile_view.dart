import 'package:flutter/material.dart';

class TileView extends StatelessWidget {
  final bool isBomb;
  final bool isPressed;

  const TileView({
    super.key,
    required this.isBomb,
    required this.isPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isPressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 60),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isBomb ? Colors.redAccent : Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isBomb
              ? const Icon(Icons.warning, color: Colors.white)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
