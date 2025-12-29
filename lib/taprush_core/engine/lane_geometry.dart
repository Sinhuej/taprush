class LaneGeometry {
  final double w;
  final double h;
  final int lanes;

  // visual
  final double gutter;
  final double laneGap;

  // tiles
  final double tileHeight;
  final double tileRadius;

  const LaneGeometry({
    required this.w,
    required this.h,
    this.lanes = 6,
    this.gutter = 16,
    this.laneGap = 10,
    this.tileHeight = 120,
    this.tileRadius = 18,
  });

  factory LaneGeometry.fromSize(double w, double h) {
    return LaneGeometry(w: w, h: h);
  }

  double get laneWidth {
    final totalGap = laneGap * (lanes - 1);
    final usable = w - (gutter * 2) - totalGap;
    return usable / lanes;
  }

  double laneLeft(int lane) {
    return gutter + lane * (laneWidth + laneGap);
  }

  int laneOfX(double x) {
    final clamped = x.clamp(0.0, w);
    final local = clamped - gutter;
    final stride = laneWidth + laneGap;

    int lane = (local / stride).floor();
    if (lane < 0) lane = 0;
    if (lane >= lanes) lane = lanes - 1;
    return lane;
  }
}
