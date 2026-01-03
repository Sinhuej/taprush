import 'dart:math';

const int kLaneCount = 6;

enum FlowDir { down, up }
enum GameMode { normal, reverse, epic }
enum HitGrade { perfect, good, miss }

class LaneGeometry {
  final double width;
  final double height;
  final double laneWidth;
  final double tileHeight;

  LaneGeometry({
    required this.width,
    required this.height,
    required this.laneWidth,
    required this.tileHeight,
  });

  static LaneGeometry fromSize(double w, double h) {
    return LaneGeometry(
      width: w,
      height: h,
      laneWidth: w / kLaneCount,
      tileHeight: 80,
    );
  }

  double laneLeft(int lane) => lane * laneWidth;

  int laneOfX(double x) {
    final lane = (x / laneWidth).floor();
    return lane.clamp(0, kLaneCount - 1);
  }

  double centerY(TapEntity e) {
    return e.dir == FlowDir.down
        ? e.y + tileHeight / 2
        : e.y - tileHeight / 2;
  }
}

class TapEntity {
  final String id;
  final int lane;
  final FlowDir dir;
  final bool isBomb;
  double y;
  bool consumed = false;

  TapEntity({
    required this.id,
    required this.lane,
    required this.dir,
    required this.isBomb,
    required this.y,
  });

  bool isMissed(LaneGeometry g) {
    return dir == FlowDir.down
        ? y > g.height
        : y + g.tileHeight < 0;
  }

  bool containsTap(LaneGeometry g, double x, double yTap) {
    if (consumed) return false;

    final left = g.laneLeft(lane);
    final right = left + g.laneWidth;

    final top = dir == FlowDir.down ? y : y - g.tileHeight;
    final bottom = top + g.tileHeight;

    return x >= left && x <= right && yTap >= top && yTap <= bottom;
  }
}

class RunStats {
  int score = 0;
  int coins = 0;
  int strikes = 0;
  int totalHits = 0;
  int perfectHits = 0;
  int bombsFlicked = 0;
  int bonusLivesEarned = 0;

  void onPerfect({int coinMult = 1}) {
    score += 2 * coinMult;
    coins += 1 * coinMult;
    totalHits++;
    perfectHits++;
  }

  void onGood({int coinMult = 1}) {
    score += 1 * coinMult;
    coins += 1 * coinMult;
    totalHits++;
  }

  void onStrike() {
    strikes++;
  }
}
