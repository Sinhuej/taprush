import 'package:flutter/material.dart';
import '../engine/models.dart';

class Board extends StatelessWidget {
  final int laneCount;
  final List<Tile> tiles;
  final double hitTop;
  final double hitBottom;

  const Board({
    super.key,
    required this.laneCount,
    required this.tiles,
    required this.hitTop,
    required this.hitBottom,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final laneW = w / laneCount;

      return Stack(
        children: [
          // Background
          Container(color: const Color(0xFF0D1117)),

          // Lane dividers
          for (int i = 1; i < laneCount; i++)
            Positioned(
              left: i * laneW,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: Colors.white12),
            ),

          // Hit zone
          Positioned(
            left: 0,
            right: 0,
            top: hitTop,
            child: Container(
              height: (hitBottom - hitTop).clamp(0, h),
              color: Colors.white10,
            ),
          ),

          // Tiles
          for (final t in tiles)
            Positioned(
              left: t.lane * laneW + 8,
              top: t.y,
              child: Container(
                width: laneW - 16,
                height: t.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.18),
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
        ],
      );
    });
  }
}
