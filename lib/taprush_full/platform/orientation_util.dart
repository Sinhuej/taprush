import 'package:flutter/widgets.dart';

enum SimpleOrientation { portrait, landscape }

SimpleOrientation simpleOrientationOf(BuildContext context) {
  final o = MediaQuery.of(context).orientation;
  return o == Orientation.portrait
      ? SimpleOrientation.portrait
      : SimpleOrientation.landscape;
}
