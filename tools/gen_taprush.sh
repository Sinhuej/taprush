#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(pwd)"
LIB="$ROOT/lib"

mkdir -p \
  "$LIB/app" \
  "$LIB/game" \
  "$LIB/ui" \
  "$LIB/bg" \
  "$LIB/settings"

###############################################################################
# lib/main.dart
###############################################################################
cat > "$LIB/main.dart" << 'DART'
import 'package:flutter/material.dart';
import 'app/taprush_app.dart';

void main() {
  runApp(const TapRushApp());
}
DART

###############################################################################
# lib/app/taprush_app.dart
###############################################################################
cat > "$LIB/app/taprush_app.dart" << 'DART'
import 'package:flutter/material.dart';
import '../game/taprush_game_screen.dart';

class TapRushApp extends StatelessWidget {
  const TapRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapRush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TapRushGameScreen(),
    );
  }
}
DART

###############################################################################
# lib/game/input_mode.dart
###############################################################################
cat > "$LIB/game/input_mode.dart" << 'DART'
enum InputMode {
  laneTap,     // A: tap a specific lane
  anywhereTap, // B: tap anywhere, engine picks best lane
}
DART

###############################################################################
# lib/game/input_controller.dart
###############################################################################
cat > "$LIB/game/input_controller.dart" << 'DART'
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
DART

###############################################################################
# lib/game/models.dart
###############################################################################
cat > "$LIB/game/models.dart" << 'DART'
class Tile {
  final int lane;       // 0..5
  double y;             // top position
  final double height;

  Tile({required this.lane, required this.y, required this.height});
}

class GameSnapshot {
  final int score;
  final int best;
  final int strikes;
  final int stage;
  final double speed;
  final bool gameOver;
  final List<Tile> tiles;

  const GameSnapshot({
    required this.score,
    required this.best,
    required this.strikes,
    required this.stage,
    required this.speed,
    required this.gameOver,
    required this.tiles,
  });
}
DART

###############################################################################
# lib/game/progression.dart
###############################################################################
cat > "$LIB/game/progression.dart" << 'DART'
class Progression {
  final int hitsPerStage;
  final double speedMultiplier;
  final double maxSpeed;

  const Progression({
    required this.hitsPerStage,
    required this.speedMultiplier,
    required this.maxSpeed,
  });

  double nextSpeed(double current, int newStage) {
    // Your rule: speed increases as stage increases. We keep it fun but cap it.
    var s = current;

    // mild ramp each stage
    s *= speedMultiplier;

    // optional “doubling punch” every stage change? uncomment if you want chaos
    // if (newStage > 0 && newStage % 1 == 0) s *= 2.0;

    if (s > maxSpeed) s = maxSpeed;
    return s;
  }
}
DART

###############################################################################
# lib/game/tile_engine.dart
###############################################################################
cat > "$LIB/game/tile_engine.dart" << 'DART'
import 'dart:math';
import 'models.dart';
import 'progression.dart';

class TileEngine {
  final int laneCount;
  final Random _rng = Random();

  // Gameplay tuning
  final double tileHeight;
  final double spawnGapMin;
  final double spawnGapMax;

  // Tap zone (relative, computed by UI)
  double tapZoneTop = 0;
  double tapZoneBottom = 0;

  // State
  int score = 0;
  int best = 0;
  int strikes = 0;
  bool gameOver = false;

  int stage = 0;
  double speed; // pixels per tick-ish (we multiply by dt)
  int _hitsThisStage = 0;

  final Progression progression;

  // Active tiles (<= 1 per lane at a time)
  final List<Tile> _tiles = [];

  // Per-lane next spawn y threshold
  final List<double> _nextSpawnAtY;

  TileEngine({
    required this.laneCount,
    required this.tileHeight,
    required this.spawnGapMin,
    required this.spawnGapMax,
    required this.speed,
    required this.progression,
  }) : _nextSpawnAtY = List<double>.filled(laneCount, 0) {
    reset();
  }

  void reset() {
    score = 0;
    strikes = 0;
    stage = 0;
    gameOver = false;
    _hitsThisStage = 0;
    _tiles.clear();

    // stagger spawns a bit so it feels alive immediately
    for (int i = 0; i < laneCount; i++) {
      _nextSpawnAtY[i] = -_rng.nextInt(500).toDouble();
    }
  }

  List<Tile> get tiles => List.unmodifiable(_tiles);

  GameSnapshot snapshot() => GameSnapshot(
        score: score,
        best: best,
        strikes: strikes,
        stage: stage,
        speed: speed,
        gameOver: gameOver,
        tiles: tiles,
      );

  // Pick best lane for "anywhere tap" mode.
  // Strategy: find a tile currently inside tap zone; choose the lowest (closest to bottom).
  // If none hittable, return -1.
  int pickBestLane() {
    Tile? bestTile;
    for (final t in _tiles) {
      if (_isHittable(t)) {
        if (bestTile == null || t.y > bestTile!.y) {
          bestTile = t;
        }
      }
    }
    return bestTile?.lane ?? -1;
  }

  // Called each frame/tick.
  // dt is seconds elapsed since last tick.
  void tick(double dt, double screenHeight) {
    if (gameOver) return;

    // spawn tiles if needed
    _spawnIfNeeded(screenHeight);

    // move tiles
    for (final t in _tiles) {
      t.y += speed * dt;
    }

    // miss detection: if any tile passes tap zone bottom without being hit
    // We consider miss when tile top is below tapZoneBottom (fully passed the zone)
    final List<Tile> toRemove = [];
    for (final t in _tiles) {
      if (t.y > tapZoneBottom) {
        // missed
        toRemove.add(t);
        _strike();
      }
    }
    _tiles.removeWhere((t) => toRemove.contains(t));
  }

  // User tapped a lane.
  void handleLaneTap(int lane) {
    if (gameOver) return;

    if (lane < 0 || lane >= laneCount) {
      _strike();
      return;
    }

    // Find the tile in that lane (if any)
    Tile? laneTile;
    for (final t in _tiles) {
      if (t.lane == lane) {
        laneTile = t;
        break;
      }
    }

    if (laneTile == null) {
      _strike();
      return;
    }

    if (_isHittable(laneTile)) {
      // HIT
      score++;
      _hitsThisStage++;
      _tiles.remove(laneTile);

      if (score > best) best = score;

      // Stage progression -> increases speed; background switching will follow stage in UI
      if (_hitsThisStage >= progression.hitsPerStage) {
        _hitsThisStage = 0;
        stage++;
        speed = progression.nextSpeed(speed, stage);
      }
    } else {
      _strike();
    }
  }

  bool _isHittable(Tile t) {
    final double tileBottom = t.y + t.height;
    // hittable if it overlaps the tap zone
    return tileBottom >= tapZoneTop && t.y <= tapZoneBottom;
  }

  void _strike() {
    strikes++;
    if (strikes >= 3) {
      gameOver = true;
    }
  }

  void _spawnIfNeeded(double screenHeight) {
    // ensure at most 1 tile per lane at a time
    final Set<int> lanesWithTile = _tiles.map((t) => t.lane).toSet();

    for (int lane = 0; lane < laneCount; lane++) {
      if (lanesWithTile.contains(lane)) continue;

      // spawn when threshold says it's time (based on y)
      // we treat _nextSpawnAtY as a y position above the screen we count down from.
      if (_nextSpawnAtY[lane] < 0) {
        // keep moving threshold towards 0 so we eventually spawn
        _nextSpawnAtY[lane] += speed * 0.016; // approx per frame
        continue;
      }

      // spawn a new tile above the screen
      final tile = Tile(
        lane: lane,
        y: -tileHeight - _rng.nextInt(200).toDouble(),
        height: tileHeight,
      );
      _tiles.add(tile);

      // schedule next spawn gap
      final gap = spawnGapMin + _rng.nextDouble() * (spawnGapMax - spawnGapMin);
      _nextSpawnAtY[lane] = -gap; // reset negative countdown
    }
  }
}
DART

###############################################################################
# lib/bg/background_store.dart (user-selected backgrounds persisted)
###############################################################################
cat > "$LIB/bg/background_store.dart" << 'DART'
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundStore {
  static const _kKeyPaths = 'taprush.bg.paths';

  Future<List<String>> loadPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKeyPaths);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> savePaths(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKeyPaths, jsonEncode(paths));
  }
}
DART

###############################################################################
# lib/bg/background_manager.dart
###############################################################################
cat > "$LIB/bg/background_manager.dart" << 'DART'
import 'dart:io';
import 'package:flutter/material.dart';
import 'background_store.dart';

class BackgroundManager extends ChangeNotifier {
  final BackgroundStore store;

  List<String> _paths = [];
  List<String> get paths => List.unmodifiable(_paths);

  BackgroundManager({required this.store});

  Future<void> init() async {
    _paths = await store.loadPaths();
    notifyListeners();
  }

  Future<void> setPaths(List<String> newPaths) async {
    _paths = newPaths.take(6).toList();
    await store.savePaths(_paths);
    notifyListeners();
  }

  Future<void> addPath(String path) async {
    if (_paths.length >= 6) return;
    _paths = [..._paths, path];
    await store.savePaths(_paths);
    notifyListeners();
  }

  Future<void> removeAt(int idx) async {
    if (idx < 0 || idx >= _paths.length) return;
    _paths = [..._paths]..removeAt(idx);
    await store.savePaths(_paths);
    notifyListeners();
  }

  Widget buildBackgroundForStage(int stage) {
    if (_paths.isEmpty) {
      // Fallback: gradient rotation by stage (copyright-safe, zero assets)
      final gradients = <List<Color>>[
        [const Color(0xFF0D1117), const Color(0xFF1A1E2E)],
        [const Color(0xFF0B1020), const Color(0xFF2A1B3D)],
        [const Color(0xFF081A14), const Color(0xFF1B2A3D)],
        [const Color(0xFF140B1F), const Color(0xFF2E1A1A)],
        [const Color(0xFF0A122A), const Color(0xFF2A2A0A)],
        [const Color(0xFF101010), const Color(0xFF2A163D)],
      ];
      final g = gradients[stage % gradients.length];
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: g,
          ),
        ),
      );
    }

    final idx = stage % _paths.length;
    final file = File(_paths[idx]);

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        // If path becomes invalid, fallback safely
        return Container(color: const Color(0xFF0D1117));
      },
    );
  }
}
DART

###############################################################################
# lib/settings/background_settings_screen.dart
###############################################################################
cat > "$LIB/settings/background_settings_screen.dart" << 'DART'
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../bg/background_manager.dart';

class BackgroundSettingsScreen extends StatefulWidget {
  final BackgroundManager bg;

  const BackgroundSettingsScreen({super.key, required this.bg});

  @override
  State<BackgroundSettingsScreen> createState() => _BackgroundSettingsScreenState();
}

class _BackgroundSettingsScreenState extends State<BackgroundSettingsScreen> {
  final picker = ImagePicker();

  Future<void> _addImage() async {
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    await widget.bg.addPath(x.path);
  }

  @override
  Widget build(BuildContext context) {
    final paths = widget.bg.paths;

    return Scaffold(
      appBar: AppBar(title: const Text('Backgrounds')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick up to 6 images. TapRush will rotate them as speed/stage increases.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: paths.length,
                itemBuilder: (context, i) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.image),
                      title: Text(paths[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await widget.bg.removeAt(i);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: paths.length >= 6 ? null : () async {
                      await _addImage();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: Text(paths.length >= 6 ? 'Limit reached (6)' : 'Add image'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
DART

###############################################################################
# lib/ui/hud.dart
###############################################################################
cat > "$LIB/ui/hud.dart" << 'DART'
import 'package:flutter/material.dart';
import '../game/input_mode.dart';

class Hud extends StatelessWidget {
  final int score;
  final int best;
  final int strikes;
  final int stage;
  final double speed;
  final InputMode inputMode;
  final VoidCallback onToggleInputMode;
  final VoidCallback onOpenBackgrounds;

  const Hud({
    super.key,
    required this.score,
    required this.best,
    required this.strikes,
    required this.stage,
    required this.speed,
    required this.inputMode,
    required this.onToggleInputMode,
    required this.onOpenBackgrounds,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(
              'Score $score  •  Best $best',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text('Strikes $strikes', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 12),
            Text('Stage $stage', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 12),
            Text('Speed ${speed.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Backgrounds',
              onPressed: onOpenBackgrounds,
              icon: const Icon(Icons.wallpaper),
            ),
            IconButton(
              tooltip: inputMode == InputMode.laneTap ? 'Input: Lane Tap' : 'Input: Anywhere Tap',
              onPressed: onToggleInputMode,
              icon: Icon(inputMode == InputMode.laneTap ? Icons.touch_app : Icons.pan_tool_alt),
            ),
          ],
        ),
      ),
    );
  }
}
DART

###############################################################################
# lib/ui/board.dart
###############################################################################
cat > "$LIB/ui/board.dart" << 'DART'
import 'package:flutter/material.dart';
import '../game/models.dart';

class Board extends StatelessWidget {
  final int laneCount;
  final List<Tile> tiles;
  final double tapZoneTop;
  final double tapZoneBottom;

  const Board({
    super.key,
    required this.laneCount,
    required this.tiles,
    required this.tapZoneTop,
    required this.tapZoneBottom,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final laneW = w / laneCount;

      return Stack(
        children: [
          // lanes
          for (int i = 0; i < laneCount; i++)
            Positioned(
              left: i * laneW,
              top: 0,
              width: laneW,
              height: h,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
              ),
            ),

          // tap zone indicator (subtle)
          Positioned(
            top: tapZoneTop,
            left: 0,
            right: 0,
            height: tapZoneBottom - tapZoneTop,
            child: Container(color: Colors.white.withOpacity(0.06)),
          ),

          // tiles
          for (final t in tiles)
            Positioned(
              left: t.lane * laneW + 6,
              top: t.y,
              width: laneW - 12,
              height: t.height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 1,
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}
DART

###############################################################################
# lib/game/taprush_game_screen.dart
###############################################################################
cat > "$LIB/game/taprush_game_screen.dart" << 'DART'
import 'dart:async';
import 'package:flutter/material.dart';

import '../bg/background_manager.dart';
import '../bg/background_store.dart';
import '../settings/background_settings_screen.dart';

import 'input_controller.dart';
import 'input_mode.dart';
import 'tile_engine.dart';
import 'progression.dart';

import '../ui/hud.dart';
import '../ui/board.dart';

class TapRushGameScreen extends StatefulWidget {
  const TapRushGameScreen({super.key});

  @override
  State<TapRushGameScreen> createState() => _TapRushGameScreenState();
}

class _TapRushGameScreenState extends State<TapRushGameScreen> {
  static const int laneCount = 6;

  late final TileEngine engine;
  late final InputController inputController;

  InputMode inputMode = InputMode.laneTap;

  late final BackgroundManager bg;

  Timer? _timer;
  DateTime _last = DateTime.now();

  // tap zone is derived from screen height each frame
  double _tapZoneTop = 0;
  double _tapZoneBottom = 0;

  @override
  void initState() {
    super.initState();

    engine = TileEngine(
      laneCount: laneCount,
      tileHeight: 110,
      spawnGapMin: 160,
      spawnGapMax: 520,
      speed: 380, // starting speed
      progression: const Progression(
        hitsPerStage: 20,       // change bg/speed every 20 hits
        speedMultiplier: 1.28,  // ramps quickly but still playable
        maxSpeed: 1600,         // cap so it stays human
      ),
    );

    inputController = InputController(mode: inputMode, laneCount: laneCount);

    bg = BackgroundManager(store: BackgroundStore());
    // init backgrounds async
    bg.init();

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final dt = now.difference(_last).inMilliseconds / 1000.0;
    _last = now;

    final h = MediaQuery.of(context).size.height;

    // tap zone sits near bottom; stable across devices
    _tapZoneTop = h * 0.72;
    _tapZoneBottom = h * 0.86;
    engine.tapZoneTop = _tapZoneTop;
    engine.tapZoneBottom = _tapZoneBottom;

    engine.tick(dt, h);

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleInputMode() {
    setState(() {
      inputMode =
          inputMode == InputMode.laneTap ? InputMode.anywhereTap : InputMode.laneTap;
      inputController.mode = inputMode;
    });
  }

  Future<void> _openBackgrounds() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BackgroundSettingsScreen(bg: bg),
      ),
    );
    if (mounted) setState(() {});
  }

  void _handleTap(TapDownDetails details) {
    final w = MediaQuery.of(context).size.width;

    final lane = inputController.resolveLane(
      tapX: details.localPosition.dx,
      screenWidth: w,
      fallbackLaneSelector: () => engine.pickBestLane(),
    );

    engine.handleLaneTap(lane);
    setState(() {});
  }

  void _restart() {
    setState(() {
      engine.reset();
      _last = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final snap = engine.snapshot();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTap,
      child: Scaffold(
        body: Stack(
          children: [
            // Background rotates with stage and uses user-selected images if present
            Positioned.fill(child: bg.buildBackgroundForStage(snap.stage)),

            // Subtle dark overlay for readability
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.20))),

            // Game board
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 56),
                child: Board(
                  laneCount: laneCount,
                  tiles: snap.tiles,
                  tapZoneTop: _tapZoneTop,
                  tapZoneBottom: _tapZoneBottom,
                ),
              ),
            ),

            // HUD
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Hud(
                score: snap.score,
                best: snap.best,
                strikes: snap.strikes,
                stage: snap.stage,
                speed: snap.speed,
                inputMode: inputMode,
                onToggleInputMode: _toggleInputMode,
                onOpenBackgrounds: _openBackgrounds,
              ),
            ),

            if (snap.gameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.65),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('GAME OVER',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text('Score: ${snap.score}',
                            style: const TextStyle(fontSize: 20)),
                        Text('Best: ${snap.best}',
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _restart,
                          child: const Text('Play Again'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          inputMode == InputMode.laneTap
                              ? 'Input: Lane Tap'
                              : 'Input: Anywhere Tap',
                          style: TextStyle(color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
DART

echo ""
echo "✅ TapRush files generated."
echo "Next: ensure dependencies: shared_preferences + image_picker"
