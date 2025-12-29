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
    final base = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF0B0B0B),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 6),
            color: Color(0x33000000),
          )
        ],
        border: isBomb
            ? Border.all(color: const Color(0xFFFF4D4D), width: 3)
            : null,
      ),
      child: isBomb
          ? const Center(
              child: Text(
                "💣",
                style: TextStyle(fontSize: 22),
              ),
            )
          : null,
    );

    return AnimatedScale(
      scale: isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 70),
      child: AnimatedOpacity(
        opacity: isPressed ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 70),
        child: base,
      ),
    );
  }
}
