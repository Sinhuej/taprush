import 'package:flutter/material.dart';

enum FxType { flickBomb, perfectRing, strikeFlash, humiliationText }

class FlickFx {
  final Offset start;
  final Offset end;
  final DateTime at;

  FlickFx({required this.start, required this.end}) : at = DateTime.now();

  double ageMs() => DateTime.now().difference(at).inMilliseconds.toDouble();
}

class TextFx {
  final String text;
  final DateTime at;

  TextFx(this.text) : at = DateTime.now();

  double ageMs() => DateTime.now().difference(at).inMilliseconds.toDouble();
}
