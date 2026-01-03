import 'dart:math';

const int kLaneCount = 4;

enum FlowDir { down, up }

enum HitGrade { perfect, good }

class RunStats {
  int score = 0;
  int coins = 0;
  int strikes = 0;
  int totalHits = 0;
  int perfectHits = 0;
  int bombsFlicked = 0;
  int bonusLivesEarned = 0;

  void onStrike() => strikes++;

  void onPerfect({required int coinMult}) {
    score += 2;
    coins += 2 * coinMult;
    totalHits++;
    perfectHits++;
  }

  void onGood({required int coinMult}) {
    score += 1;
    coins += 1 * coinMult;
    totalHits++;
  }
}

class TapEntity {
  final String id;
  final int lane;
  final FlowDir dir;
  final bool isBomb;

  double y;
  bool consumed = false; // 🔒 HARD GUARD

  TapEntity({
    required this.id,
    required this.lane,
    required this.dir,
    required this.isBomb,
    required this.y,
  });

  bool isMissed(LaneGeometry g) {
    return dir == FlowDir.down ? y > g.height : y < -g.tileHeight;
  }

  double centerY(LaneGeometry g) {
    return dir == FlowDir.down
        ? y + g.tileHeight / 2
        : y - g.tileHeight / 2;
  }
}

class LaneGeometry {
  final double width;
  final double height;
  final double laneWidth;
  final double tileHeight;

  LaneGeometry._(
    this.width,
    this.height,
    this.laneWidth,
    this.tileHeight,
  );

  static LaneGeometry fromSize(double w, double h) {
    final laneWidth = w / kLaneCount;
    return LaneGeometry._(w, h, laneWidth, 64);
  }

  double laneLeft(int lane) => lane * laneWidth;

  int laneOfX(double x) =>
      max(0, min(kLaneCount - 1, (x / laneWidth).floor()));
}
