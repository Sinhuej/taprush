import 'dart:math';
import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../anti_cheat/cheat_sequence.dart';
import '../visuals/color_mode.dart';
import '../visuals/color_palette.dart';

class Board extends StatelessWidget {
  final int laneCount;
  final List<Tile> tiles;
  final CheatSequence? cheatSeq;
  final ColorMode colorMode;

  const Board({
    super.key,
    required this.laneCount,
    required this.tiles,
    required this.colorMode,
    this.cheatSeq,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final laneW = w / laneCount;
      final center = Offset(w / 2, h / 2);

      Offset pos(Tile t) {
        final base = Offset(t.lane * laneW + 8, t.y);
        if (cheatSeq == null) return base;

        final p = cheatSeq!.progress.clamp(0.0, 1.0);
        switch (cheatSeq!.phase) {
          case CheatVisualPhase.pullIn:
            return Offset.lerp(base, center, p * 0.85)!;
          case CheatVisualPhase.compress:
            final jitter = (Random(t.id).nextDouble() - 0.5) * 6;
            return base.translate(jitter, sin(p * pi * 6) * 4);
          case CheatVisualPhase.explode:
            final dir = base - center;
            final norm =
                dir.distance == 0 ? const Offset(1, 0) : dir / dir.distance;
            return base + norm * (p * 420);
        }
      }

      Color tileColor(Tile t) {
        if (colorMode == ColorMode.multi) {
          return ColorPalette.pick(t.id);
        }
        return Colors.white.withOpacity(0.18);
      }

      return Stack(
        children: [
          Container(color: const Color(0xFF0D1117)),

          for (int i = 1; i < laneCount; i++)
            Positioned(
              left: i * laneW,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: Colors.white12),
            ),

          for (final t in tiles)
            Positioned(
              left: pos(t).dx,
              top: pos(t).dy,
              child: Container(
                width: laneW - 16,
                height: t.height,
                decoration: BoxDecoration(
                  color: tileColor(t),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
        ],
      );
    });
  }
}
