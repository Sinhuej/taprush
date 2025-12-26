import 'package:flutter/material.dart';

class ColorPalette {
  static const List<Color> multi = [
    Color(0xFF00E5FF),
    Color(0xFF7C4DFF),
    Color(0xFFFF5252),
    Color(0xFF69F0AE),
    Color(0xFFFFD740),
    Color(0xFFFF6E40),
  ];

  static Color pick(int seed) {
    return multi[seed % multi.length];
  }
}
