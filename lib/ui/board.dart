import 'dart:math';
import 'package:flutter/material.dart';
import '../engine/models.dart';
import '../anti_cheat/cheat_sequence.dart';

class Board extends StatelessWidget {
  final int laneCount;
  final List<Tile> tiles;

  // Anti-cheat visuals (nullable when inactive)
  final CheatSequence? cheatSeq;

  const Board({
    super.key,
    required this.laneCount,
    required this.tiles,
    this.cheatSeq,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final laneW = w / laneCount;
      final center = Offset(w / 2, h / 2);

      Offset transformedPos(Tile t) {
        final baseX = t.lane * laneW + 8;
        final baseY = t.y;
        final base = Offset(baseX, baseY);

        if (cheatSeq == null) return base;

        final p = cheatSeq!.progress.clamp(0.0, 1.0);
        switch (cheatSeq!.phase) {
          case CheatVisualPhase.pullIn:
            return Offset.lerp(base, center, p * 0.85)!;
          case CheatVisualPhase.compress:
            final jitter = (Random(t.id).nextDouble() - 0.5) * 6.0;
            return Offset(
              base.dx + jitter,
              base.dy + sin(p * pi * 6) * 4,
            );
          case CheatVisualPhase.explode:
            final dir = (base - center);
            final norm = dir.distance == 0 ? Offset(1, 0) : dir / dir.distance;
            return base + norm * (p * 420);
        }
      }

      double transformedScale() {
        if (cheatSeq == null) return 1.0;
        final p = cheatSeq!.progress;
        switch (cheatSeq!.phase) {
          case CheatVisualPhase.pullIn:
            return 1.0;
          case CheatVisualPhase.compress:
            return 1.0 - (p * 0.25);
          case CheatVisualPhase.explode:
            return max(0.2, 1.0 - p);
        }
      }

      double transformedOpacity() {
        if (cheatSeq == null) return 1.0;
        if (cheatSeq!.phase == CheatVisualPhase.explode) {
          return max(0.0, 1.0 - cheatSeq!.progress);
        }
        return 1.0;
      }

      return Stack(
        children: [
          Container(color: const Color(0xFF0D1117)),

          // Lane dividers
          for (int i = 1; i < laneCount; i++)
            Positioned(
              left: i * laneW,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: Colors.white12),
            ),

          // Tiles
          for (final t in tiles)
            Builder(builder: (_) {
              final pos = transformedPos(t);
              return Positioned(
                left: pos.dx,
                top: pos.dy,
                child: Opacity(
                  opacity: transformedOpacity(),
                  child: Transform.scale(
                    scale: transformedScale(),
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
                ),
              );
            }),
        ],
      );
    });
  }
}
