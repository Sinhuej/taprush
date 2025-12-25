import 'package:flutter/material.dart';
import '../game/models.dart';
import '../skins/skin.dart';
import '../game/scroll_direction.dart';

class Board extends StatelessWidget {
  final int laneCount;
  final List<Tile> tiles;

  // zones:
  final double topZoneTop;
  final double topZoneBottom;
  final double bottomZoneTop;
  final double bottomZoneBottom;

  final Skin skin;

  const Board({
    super.key,
    required this.laneCount,
    required this.tiles,
    required this.topZoneTop,
    required this.topZoneBottom,
    required this.bottomZoneTop,
    required this.bottomZoneBottom,
    required this.skin,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final laneW = w / laneCount;

      final colorA = Color(skin.colorA);
      final colorB = Color(skin.colorB);

      return Stack(
        children: [
          for (int i = 0; i < laneCount; i++)
            Positioned(
              left: i * laneW,
              top: 0,
              width: laneW,
              height: h,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
              ),
            ),

          // Top tap zone
          Positioned(
            top: topZoneTop,
            left: 0,
            right: 0,
            height: (topZoneBottom - topZoneTop).clamp(0, double.infinity),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),

          // Bottom tap zone
          Positioned(
            top: bottomZoneTop,
            left: 0,
            right: 0,
            height: (bottomZoneBottom - bottomZoneTop).clamp(0, double.infinity),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),

          for (final t in tiles)
            Positioned(
              left: t.lane * laneW + 6,
              top: t.y,
              width: laneW - 12,
              height: t.height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: t.dir == ScrollDirection.down ? Alignment.topLeft : Alignment.bottomLeft,
                    end: t.dir == ScrollDirection.down ? Alignment.bottomRight : Alignment.topRight,
                    colors: [colorA, colorB],
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: skin.glow ? 18 : 10,
                      spreadRadius: skin.glow ? 2 : 1,
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}
