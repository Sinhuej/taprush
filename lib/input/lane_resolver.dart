int resolveLane({
  required double tapX,
  required double screenW,
  required int laneCount,
}) {
  final laneW = screenW / laneCount;
  final lane = (tapX / laneW).floor();
  if (lane < 0) return 0;
  if (lane >= laneCount) return laneCount - 1;
  return lane;
}
