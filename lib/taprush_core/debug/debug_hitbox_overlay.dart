import 'package:flutter/material.dart';
import '../engine/models.dart';

class DebugHitboxOverlay extends StatelessWidget {
  final LaneGeometry g;
  final List<TapEntity> entities;
  final Offset? tap;

  const DebugHitboxOverlay({
    super.key,
    required this.g,
    required this.entities,
    required this.tap,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _Painter(g, entities, tap),
        size: Size(g.width, g.height),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final LaneGeometry g;
  final List<TapEntity> entities;
  final Offset? tap;

  _Painter(this.g, this.entities, this.tap);

  @override
  void paint(Canvas c, Size s) {
    final lanePaint = Paint()
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < kLaneCount; i++) {
      c.drawRect(
        Rect.fromLTWH(g.laneLeft(i), 0, g.laneWidth, g.height),
        lanePaint,
      );
    }

    final entityPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final e in entities) {
      final top = e.dir == FlowDir.down ? e.y : e.y - g.tileHeight;
      final rect = Rect.fromLTWH(
        g.laneLeft(e.lane),
        top,
        g.laneWidth,
        g.tileHeight,
      );
      entityPaint.color = e.isBomb ? Colors.red : Colors.green;
      c.drawRect(rect, entityPaint);
    }

    if (tap != null) {
      c.drawCircle(
        tap!,
        8,
        Paint()..color = Colors.yellow,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
