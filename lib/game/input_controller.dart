import 'input_mode.dart';

class InputController {
  InputMode mode;
  final int laneCount;

  InputController({
    required this.mode,
    required this.laneCount,
  });

  int resolveLane({
    required double tapX,
    required double screenWidth,
    required int Function() fallbackLaneSelector,
  }) {
    if (mode == InputMode.anywhereTap) {
      return fallbackLaneSelector();
    }
    final laneWidth = screenWidth / laneCount;
    final lane = (tapX / laneWidth).floor();
    return lane.clamp(0, laneCount - 1);
    }
}
