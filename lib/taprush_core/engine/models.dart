import 'dart:math';

const int kLaneCount = 6;

enum GameMode { normal, reverse, epic }
enum FlowDir { down, up }
enum HitGrade { perfect, good }

class LaneGeometry {
  final double width;
  final double height;
  final double laneWidth;
  final double tileHeight;

  LaneGeometry._(this.width, this.height, this.laneWidth, this.tileHeight);

  factory LaneGeometry.fromSize(double w, double h) {
    final laneW = w / kLaneCount;
    final tileH = laneW * 1.6;
    return LaneGeometry._(w, h, laneW, tileH);
  }

  int laneOfX(double x) =>
      (x ~/ laneWidth).clamp(0, kLaneCount - 1);

  double laneLeft(int lane) => lane * laneWidth;
}

class TapEntity {
  final String id;
  final int lane;
  final FlowDir dir;
  final bool isBomb;
  double y;

  TapEntity({
    required this.id,
    required this.lane,
    required this.dir,
    required this.isBomb,
    required this.y,
  });

  bool containsTap({
    required LaneGeometry g,
    required double tapX,
    required double tapY,
  }) {
    final left = g.laneLeft(lane);
    final right = left + g.laneWidth;
    final top = dir == FlowDir.down ? y : y - g.tileHeight;
    final bottom = top + g.tileHeight;

    return tapX >= left &&
        tapX <= right &&
        tapY >= top &&
        tapY <= bottom;
  }

  double centerY(LaneGeometry g) =>
      dir == FlowDir.down ? y + g.tileHeight / 2 : y - g.tileHeight / 2;

  bool isMissed(LaneGeometry g) {
    if (dir == FlowDir.down) return y > g.height + g.tileHeight;
    return y < -g.tileHeight;
  }
}

class RunStats {
  int score = 0;
  int coins = 0;
  int strikes = 0;

  int totalHits = 0;
  int perfectHits = 0;

  // 🔥 NEW
  int bombsFlicked = 0;
  int bonusLivesEarned = 0;

  double get accuracy =>
      totalHits == 0 ? 1.0 : perfectHits / totalHits;

  void onPerfect({required int coinMult}) {
    totalHits++;
    perfectHits++;
    score += 2;
    coins += 2 * coinMult;
  }

  void onGood({required int coinMult}) {
    totalHits++;
    score += 1;
    coins += 1 * coinMult;
  }

  void onStrike() {
    strikes++;
  }
}
