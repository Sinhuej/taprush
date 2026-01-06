import 'package:flutter/material.dart';
import 'debug_log.dart';

class DebugOverlay extends StatelessWidget {
  const DebugOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final events = DebugLog.snapshot().reversed.toList();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 220,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: ListView(
          padding: const EdgeInsets.all(6),
          children: [
            for (final e in events)
              Text(
                '[${e.time.toStringAsFixed(2)}] ${e.tag}: ${e.message}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.greenAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
