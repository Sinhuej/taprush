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

  const LaneGeometry({
    required this.width,
    required this.height,
    required this.laneWidth,
    required this.tileHeight,
  });

  factory LaneGeometry.fromSize(double width, double height) {
    final laneW = width / kLaneCount;
    // Tile height tuned for finger accuracy + visibility
    final tileH = max(72.0, height * 0.14);
    return LaneGeometry(width: width, height: height, laneWidth: laneW, tileHeight: tileH);
  }

  int laneOfX(double x) {
    final lane = (x / laneWidth).floor();
    return lane.clamp(0, kLaneCount - 1);
  }

  double laneLeft(int lane) => lane * laneWidth;
}

class TapEntity {
  final String id;
  final int lane; // 0..5
  final FlowDir dir;
  final bool isBomb;

  // y is the top edge for down-flow, bottom edge for up-flow (keeps math simple)
  double y;

  TapEntity({
    required this.id,
    required this.lane,
    required this.dir,
    required this.isBomb,
    required this.y,
  });

  // Rect for hit test
  bool containsTap({
    required LaneGeometry g,
    required double tapX,
    required double tapY,
  }) {
    final left = g.laneLeft(lane);
    final right = left + g.laneWidth;

    final top = dir == FlowDir.down ? y : (y - g.tileHeight);
    final bottom = top + g.tileHeight;

    return tapX >= left && tapX <= right && tapY >= top && tapY <= bottom;
  }

  double centerY(LaneGeometry g) {
    final top = dir == FlowDir.down ? y : (y - g.tileHeight);
    return top + (g.tileHeight / 2);
  }

  bool isMissed(LaneGeometry g) {
    // Miss occurs if tile exits the screen without being tapped.
    // Bombs can also be "missed" safely, but we still remove them for cleanup.
    if (dir == FlowDir.down) {
      final top = y;
      return top > g.height;
    } else {
      final bottom = y;
      return bottom < 0;
    }
  }
}

class RunStats {
  int score = 0;
  int strikes = 0;
  int coins = 0;

  int perfectStreak = 0;

  int totalHits = 0;
  int perfectHits = 0;

  double get accuracy => totalHits == 0 ? 1.0 : perfectHits / totalHits;

  void onPerfect({required int coinMult}) {
    score += 1;
    totalHits += 1;
    perfectHits += 1;
    perfectStreak += 1;

    coins += 1 * coinMult;

    // LOCKED: every 10 perfect hits in a row => +5 bonus coins
    if (perfectStreak % 10 == 0) {
      coins += 5 * coinMult;
    }
  }

  void onGood({required int coinMult}) {
    score += 1;
    totalHits += 1;
    perfectStreak = 0;
    coins += 1 * coinMult;
  }

  void onStrike() {
    strikes += 1;
    perfectStreak = 0;
  }
}
