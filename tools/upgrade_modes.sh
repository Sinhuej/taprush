#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(pwd)"
LIB="$ROOT/lib"

mkdir -p \
  "$LIB/modes" \
  "$LIB/storage" \
  "$LIB/game" \
  "$LIB/ui"

###############################################################################
# lib/modes/game_mode.dart
###############################################################################
cat > "$LIB/modes/game_mode.dart" << 'DART'
enum GameMode {
  classic,
  reverse,
  epic,
}

extension GameModeX on GameMode {
  String get key {
    switch (this) {
      case GameMode.classic: return 'classic';
      case GameMode.reverse: return 'reverse';
      case GameMode.epic: return 'epic';
    }
  }

  String get label {
    switch (this) {
      case GameMode.classic: return 'Classic';
      case GameMode.reverse: return 'Reverse';
      case GameMode.epic: return 'Epic';
    }
  }

  int get coinMultiplier {
    switch (this) {
      case GameMode.classic: return 1;
      case GameMode.reverse: return 2;
      case GameMode.epic: return 3;
    }
  }
}
DART

###############################################################################
# lib/storage/high_score_store.dart
###############################################################################
cat > "$LIB/storage/high_score_store.dart" << 'DART'
import 'package:shared_preferences/shared_preferences.dart';
import '../modes/game_mode.dart';

class HighScoreStore {
  String _key(GameMode mode) => 'taprush.highscore.${mode.key}';

  Future<int> load(GameMode mode) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_key(mode)) ?? 0;
  }

  Future<int> saveIfHigher(GameMode mode, int score) async {
    final p = await SharedPreferences.getInstance();
    final key = _key(mode);
    final current = p.getInt(key) ?? 0;
    if (score > current) {
      await p.setInt(key, score);
      return score;
    }
    return current;
  }
}
DART

###############################################################################
# lib/storage/mode_unlock_store.dart
###############################################################################
cat > "$LIB/storage/mode_unlock_store.dart" << 'DART'
import 'package:shared_preferences/shared_preferences.dart';
import '../modes/game_mode.dart';

class ModeUnlockStore {
  String _key(GameMode mode) => 'taprush.mode.unlocked.${mode.key}';

  Future<bool> isUnlocked(GameMode mode) async {
    if (mode == GameMode.classic) return true;
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key(mode)) ?? false;
  }

  Future<void> unlock(GameMode mode) async {
    if (mode == GameMode.classic) return;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(mode), true);
  }
}
DART

###############################################################################
# lib/game/scroll_direction.dart
###############################################################################
cat > "$LIB/game/scroll_direction.dart" << 'DART'
enum ScrollDirection { down, up }
DART

###############################################################################
# lib/game/models.dart  (REWRITE to include direction)
###############################################################################
cat > "$LIB/game/models.dart" << 'DART'
import 'scroll_direction.dart';

class Tile {
  final int lane; // 0..5
  double y;
  final double height;
  final ScrollDirection dir;

  Tile({
    required this.lane,
    required this.y,
    required this.height,
    required this.dir,
  });
}

class GameSnapshot {
  final int score;
  final int strikes;
  final int stage;
  final double speed;
  final bool gameOver;
  final bool epicRetryAvailable; // prompt should show if true
  final List<Tile> tiles;

  const GameSnapshot({
    required this.score,
    required this.strikes,
    required this.stage,
    required this.speed,
    required this.gameOver,
    required this.epicRetryAvailable,
    required this.tiles,
  });
}
DART

###############################################################################
# lib/game/progression.dart (keep / overwrite safe)
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
    var s = current * speedMultiplier;
    if (newStage > 0 && newStage % 3 == 0) s *= 2.0; // “spice” moment
    if (s > maxSpeed) s = maxSpeed;
    return s;
  }
}
DART

###############################################################################
# lib/game/tile_engine.dart  (REWRITE: 5 strikes + modes + epic dual directions)
###############################################################################
cat > "$LIB/game/tile_engine.dart" << 'DART'
import 'dart:math';
import '../modes/game_mode.dart';
import 'models.dart';
import 'progression.dart';
import 'scroll_direction.dart';

class TileEngine {
  final int laneCount;
  final Random _rng = Random();

  final double tileHeight;
  final double spawnGapMin;
  final double spawnGapMax;

  // Tap zones are computed by UI each frame
  // Classic: uses bottom zone
  // Reverse: uses top zone
  // Epic: uses BOTH
  double tapZoneTopA = 0;      // top zone start
  double tapZoneBottomA = 0;   // top zone end
  double tapZoneTopB = 0;      // bottom zone start
  double tapZoneBottomB = 0;   // bottom zone end

  final Progression progression;

  // State
  GameMode mode = GameMode.classic;

  int score = 0;
  int strikes = 0;        // classic+reverse: 0..5, epic: unused (kept 0)
  bool gameOver = false;

  bool epicRetryUsed = false; // one retry per run
  bool epicRetryPrompt = false;

  int stage = 0;
  double speed;
  int _hitsThisStage = 0;

  final List<Tile> _tiles = [];
  final List<double> _nextSpawnCountdown;

  TileEngine({
    required this.laneCount,
    required this.tileHeight,
    required this.spawnGapMin,
    required this.spawnGapMax,
    required this.speed,
    required this.progression,
  }) : _nextSpawnCountdown = List<double>.filled(laneCount, 0) {
    reset(GameMode.classic);
  }

  void reset(GameMode newMode) {
    mode = newMode;
    score = 0;
    strikes = 0;
    gameOver = false;
    stage = 0;
    _hitsThisStage = 0;
    _tiles.clear();

    epicRetryUsed = false;
    epicRetryPrompt = false;

    for (int i = 0; i < laneCount; i++) {
      _nextSpawnCountdown[i] = _rng.nextDouble() * 0.8; // seconds
    }
  }

  List<Tile> get tiles => List.unmodifiable(_tiles);

  GameSnapshot snapshot() => GameSnapshot(
    score: score,
    strikes: strikes,
    stage: stage,
    speed: speed,
    gameOver: gameOver,
    epicRetryAvailable: (mode == GameMode.epic && epicRetryPrompt && !epicRetryUsed),
    tiles: tiles,
  );

  // Anywhere tap: choose best hittable tile depending on mode
  int pickBestLane() {
    Tile? bestTile;
    for (final t in _tiles) {
      if (_isHittable(t)) {
        if (bestTile == null || _priorityY(t) > _priorityY(bestTile!)) {
          bestTile = t;
        }
      }
    }
    return bestTile?.lane ?? -1;
  }

  double _priorityY(Tile t) {
    // For down tiles, closer to bottom is higher y.
    // For up tiles, closer to top is lower y, so invert.
    if (t.dir == ScrollDirection.down) return t.y;
    return -t.y;
  }

  void tick(double dt, double screenHeight) {
    if (gameOver) return;

    _spawnIfNeeded(dt, screenHeight);

    // move
    for (final t in _tiles) {
      if (t.dir == ScrollDirection.down) {
        t.y += speed * dt;
      } else {
        t.y -= speed * dt;
      }
    }

    // misses / escapes
    final List<Tile> toRemove = [];
    for (final t in _tiles) {
      if (mode == GameMode.epic) {
        // Epic: any escape = loss prompt
        if (t.dir == ScrollDirection.down) {
          if (t.y > screenHeight) {
            toRemove.add(t);
            _epicLose();
          }
        } else {
          if (t.y + t.height < 0) {
            toRemove.add(t);
            _epicLose();
          }
        }
      } else {
        // Classic/Reverse: miss if passes the active tap zone
        if (mode == GameMode.classic && t.dir == ScrollDirection.down) {
          if (t.y > tapZoneBottomB) { toRemove.add(t); _strike(); }
        } else if (mode == GameMode.reverse && t.dir == ScrollDirection.up) {
          if (t.y + t.height < tapZoneTopA) { toRemove.add(t); _strike(); }
        } else {
          // safety: remove stray tiles if any
          if (t.y > screenHeight + 500 || t.y < -500) toRemove.add(t);
        }
      }
    }
    _tiles.removeWhere((t) => toRemove.contains(t));
  }

  void handleLaneTap(int lane) {
    if (gameOver) return;

    if (lane < 0 || lane >= laneCount) {
      if (mode != GameMode.epic) _strike();
      return;
    }

    // find a tile in lane that is hittable; in epic there may be either direction
    Tile? candidate;
    for (final t in _tiles) {
      if (t.lane == lane && _isHittable(t)) {
        // choose the “best” hittable in that lane
        if (candidate == null || _priorityY(t) > _priorityY(candidate!)) candidate = t;
      }
    }

    if (candidate == null) {
      if (mode != GameMode.epic) _strike();
      return;
    }

    // HIT
    score++;
    _hitsThisStage++;
    _tiles.remove(candidate);

    if (_hitsThisStage >= progression.hitsPerStage) {
      _hitsThisStage = 0;
      stage++;
      speed = progression.nextSpeed(speed, stage);
    }
  }

  bool _isHittable(Tile t) {
    // Zone A = top; Zone B = bottom
    if (mode == GameMode.classic) {
      // only bottom zone matters; tiles go down
      final tileBottom = t.y + t.height;
      return tileBottom >= tapZoneTopB && t.y <= tapZoneBottomB;
    }

    if (mode == GameMode.reverse) {
      // only top zone matters; tiles go up
      final tileBottom = t.y + t.height;
      return tileBottom >= tapZoneTopA && t.y <= tapZoneBottomA;
    }

    // Epic: both zones active depending on tile direction
    if (t.dir == ScrollDirection.down) {
      final tileBottom = t.y + t.height;
      return tileBottom >= tapZoneTopB && t.y <= tapZoneBottomB;
    } else {
      final tileBottom = t.y + t.height;
      return tileBottom >= tapZoneTopA && t.y <= tapZoneBottomA;
    }
  }

  void _strike() {
    strikes++;
    if (strikes >= 5) {
      gameOver = true;
    }
  }

  void _epicLose() {
    // Epic: prompt retry (once). Do not consume retry automatically.
    gameOver = true;
    epicRetryPrompt = true;
  }

  // Called by UI only when reward ad is earned and retry is allowed
  void epicRetryContinue(double screenHeight) {
    if (mode != GameMode.epic) return;
    if (epicRetryUsed) return;

    epicRetryUsed = true;
    epicRetryPrompt = false;
    gameOver = false;

    // Clear board and re-seed spawns safely (no free points)
    _tiles.clear();
    for (int i = 0; i < laneCount; i++) {
      _nextSpawnCountdown[i] = 0.25 + _rng.nextDouble() * 0.6;
    }
  }

  void _spawnIfNeeded(double dt, double screenHeight) {
    final lanesWithTile = _tiles.map((t) => t.lane).toSet();

    for (int lane = 0; lane < laneCount; lane++) {
      if (lanesWithTile.contains(lane)) continue;

      _nextSpawnCountdown[lane] -= dt;
      if (_nextSpawnCountdown[lane] > 0) continue;

      if (mode == GameMode.classic) {
        _tiles.add(Tile(
          lane: lane,
          dir: ScrollDirection.down,
          y: -tileHeight - _rng.nextInt(240).toDouble(),
          height: tileHeight,
        ));
      } else if (mode == GameMode.reverse) {
        _tiles.add(Tile(
          lane: lane,
          dir: ScrollDirection.up,
          y: screenHeight + tileHeight + _rng.nextInt(240).toDouble(),
          height: tileHeight,
        ));
      } else {
        // Epic: random direction per spawn
        final dir = _rng.nextBool() ? ScrollDirection.down : ScrollDirection.up;
        _tiles.add(Tile(
          lane: lane,
          dir: dir,
          y: dir == ScrollDirection.down
              ? (-tileHeight - _rng.nextInt(240).toDouble())
              : (screenHeight + tileHeight + _rng.nextInt(240).toDouble()),
          height: tileHeight,
        ));
      }

      final gap = spawnGapMin + _rng.nextDouble() * (spawnGapMax - spawnGapMin);
      _nextSpawnCountdown[lane] = (gap / speed).clamp(0.12, 1.1);
    }
  }
}
DART

###############################################################################
# lib/ui/mode_select_screen.dart  (unlock reverse/epic with coins)
###############################################################################
cat > "$LIB/ui/mode_select_screen.dart" << 'DART'
import 'package:flutter/material.dart';
import '../modes/game_mode.dart';
import '../storage/mode_unlock_store.dart';
import '../economy/coin_manager.dart';

class ModeSelectResult {
  final GameMode mode;
  const ModeSelectResult(this.mode);
}

class ModeSelectScreen extends StatefulWidget {
  final CoinManager coins;
  final ModeUnlockStore unlocks;
  final GameMode current;

  const ModeSelectScreen({
    super.key,
    required this.coins,
    required this.unlocks,
    required this.current,
  });

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  bool reverseUnlocked = false;
  bool epicUnlocked = false;

  static const int reverseCost = 20000;
  static const int epicCost = 50000;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    reverseUnlocked = await widget.unlocks.isUnlocked(GameMode.reverse);
    epicUnlocked = await widget.unlocks.isUnlocked(GameMode.epic);
    if (mounted) setState(() {});
  }

  Future<void> _unlock(GameMode mode) async {
    final cost = mode == GameMode.reverse ? reverseCost : epicCost;
    final ok = await widget.coins.spend(cost);
    if (!ok) return;
    await widget.unlocks.unlock(mode);
    await _load();
  }

  Widget _row(GameMode mode, bool unlocked, int cost, String subtitle) {
    return Card(
      child: ListTile(
        title: Text(mode.label),
        subtitle: Text(subtitle),
        trailing: unlocked
          ? ElevatedButton(
              onPressed: () => Navigator.of(context).pop(ModeSelectResult(mode)),
              child: const Text('Select'),
            )
          : OutlinedButton(
              onPressed: widget.coins.coins >= cost ? () => _unlock(mode) : null,
              child: Text('Unlock $cost'),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Modes')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coins: ${widget.coins.coins}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row(GameMode.classic, true, 0, 'Tiles fall • 5 strikes • 1× coins'),
            _row(GameMode.reverse, reverseUnlocked, reverseCost, 'Tiles rise • 5 strikes • 2× coins • separate high score'),
            _row(GameMode.epic, epicUnlocked, epicCost, 'Up + Down • escape = loss • 3× coins • 1 ad retry per run • separate high score'),
          ],
        ),
      ),
    );
  }
}
DART

###############################################################################
# lib/ui/board.dart  (update tile drawing to respect direction visually)
###############################################################################
cat > "$LIB/ui/board.dart" << 'DART'
import 'package:flutter/material.dart';
import '../game/models.dart';
import '../skins/skin.dart';
import '../game/scroll_direction.dart';

class Board extends StatelessWidget {
  final int laneCount;
  final List<Tile> tiles;

  // zones:
  final double topZoneTop;
  final double topZoneBottom;
  final double bottomZoneTop;
  final double bottomZoneBottom;

  final Skin skin;

  const Board({
    super.key,
    required this.laneCount,
    required this.tiles,
    required this.topZoneTop,
    required this.topZoneBottom,
    required this.bottomZoneTop,
    required this.bottomZoneBottom,
    required this.skin,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final laneW = w / laneCount;

      final colorA = Color(skin.colorA);
      final colorB = Color(skin.colorB);

      return Stack(
        children: [
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

          // Top tap zone
          Positioned(
            top: topZoneTop,
            left: 0,
            right: 0,
            height: (topZoneBottom - topZoneTop).clamp(0, double.infinity),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),

          // Bottom tap zone
          Positioned(
            top: bottomZoneTop,
            left: 0,
            right: 0,
            height: (bottomZoneBottom - bottomZoneTop).clamp(0, double.infinity),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),

          for (final t in tiles)
            Positioned(
              left: t.lane * laneW + 6,
              top: t.y,
              width: laneW - 12,
              height: t.height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: t.dir == ScrollDirection.down ? Alignment.topLeft : Alignment.bottomLeft,
                    end: t.dir == ScrollDirection.down ? Alignment.bottomRight : Alignment.topRight,
                    colors: [colorA, colorB],
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: skin.glow ? 18 : 10,
                      spreadRadius: skin.glow ? 2 : 1,
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
# lib/game/taprush_game_screen.dart  (REWRITE to integrate mode + scores + coins + epic retry prompt)
###############################################################################
cat > "$LIB/game/taprush_game_screen.dart" << 'DART'
import 'dart:async';
import 'package:flutter/material.dart';

import '../ui/banner_frame.dart';
import '../ui/hud.dart';
import '../ui/board.dart';
import '../ui/mode_select_screen.dart';
import '../ui/skin_shop_screen.dart';

import '../bg/background_manager.dart';
import '../bg/background_store.dart';
import '../settings/background_settings_screen.dart';

import '../economy/coin_manager.dart';
import '../economy/coin_store.dart';

import '../skins/skin_manager.dart';
import '../skins/skin_state_store.dart';

import '../ads/interstitial_manager.dart';
import '../ads/reward_ad_manager.dart';

import '../modes/game_mode.dart';
import '../storage/high_score_store.dart';
import '../storage/mode_unlock_store.dart';

import 'input_controller.dart';
import 'input_mode.dart';
import 'tile_engine.dart';
import 'progression.dart';

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

  late final CoinManager coins;
  late final SkinManager skins;

  final HighScoreStore highScores = HighScoreStore();
  final ModeUnlockStore unlocks = ModeUnlockStore();

  int bestForMode = 0;
  GameMode currentMode = GameMode.classic;

  final InterstitialManager interstitials = InterstitialManager();
  final RewardAdManager rewards = RewardAdManager();

  Timer? _timer;
  DateTime _last = DateTime.now();

  // Zones (top + bottom)
  double _topZoneTop = 0;
  double _topZoneBottom = 0;
  double _bottomZoneTop = 0;
  double _bottomZoneBottom = 0;

  bool _epicRetryDialogShowing = false;

  @override
  void initState() {
    super.initState();

    engine = TileEngine(
      laneCount: laneCount,
      tileHeight: 110,
      spawnGapMin: 180,
      spawnGapMax: 560,
      speed: 420,
      progression: const Progression(
        hitsPerStage: 20,
        speedMultiplier: 1.28,
        maxSpeed: 1900,
      ),
    );

    inputController = InputController(mode: inputMode, laneCount: laneCount);

    bg = BackgroundManager(store: BackgroundStore());
    bg.init();

    coins = CoinManager(CoinStore());
    coins.init().then((_) => setState(() {}));

    skins = SkinManager(SkinStateStore());
    skins.init().then((_) => setState(() {}));

    _loadBest();

    interstitials.preload();
    rewards.preload();

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  Future<void> _loadBest() async {
    bestForMode = await highScores.load(currentMode);
    if (mounted) setState(() {});
  }

  void _applyZones(double screenH) {
    // Top zone near top; bottom zone near bottom.
    _topZoneTop = screenH * 0.10;
    _topZoneBottom = screenH * 0.22;

    _bottomZoneTop = screenH * 0.72;
    _bottomZoneBottom = screenH * 0.86;

    engine.tapZoneTopA = _topZoneTop;
    engine.tapZoneBottomA = _topZoneBottom;
    engine.tapZoneTopB = _bottomZoneTop;
    engine.tapZoneBottomB = _bottomZoneBottom;
  }

  void _tick() {
    final now = DateTime.now();
    final dt = now.difference(_last).inMilliseconds / 1000.0;
    _last = now;

    final h = MediaQuery.of(context).size.height;
    _applyZones(h);

    engine.tick(dt, h);

    // Epic retry prompt handling (PROMPT, not auto)
    final snap = engine.snapshot();
    if (snap.gameOver && snap.epicRetryAvailable && !_epicRetryDialogShowing) {
      _epicRetryDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showEpicRetryPrompt(h));
    }

    if (mounted) setState(() {});
  }

  Future<void> _showEpicRetryPrompt(double screenH) async {
    if (!mounted) return;

    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Epic Retry?'),
        content: const Text('Watch 1 ad to get one retry? (Only once per run)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Watch Ad'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (choice == true) {
      rewards.preload();
      final ok = await rewards.show(onEarned: () {});
      if (ok) {
        engine.epicRetryContinue(screenH);
      }
    }

    _epicRetryDialogShowing = false;
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleInputMode() {
    setState(() {
      inputMode = inputMode == InputMode.laneTap ? InputMode.anywhereTap : InputMode.laneTap;
      inputController.mode = inputMode;
    });
  }

  Future<void> _openBackgrounds() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BackgroundSettingsScreen(bg: bg)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openSkins() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SkinShopScreen(coins: coins, skins: skins, rewards: rewards)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openModes() async {
    final res = await Navigator.of(context).push<ModeSelectResult>(
      MaterialPageRoute(builder: (_) => ModeSelectScreen(coins: coins, unlocks: unlocks, current: currentMode)),
    );

    if (res == null) return;

    // Ensure unlocked
    final ok = await unlocks.isUnlocked(res.mode);
    if (!ok) return;

    setState(() {
      currentMode = res.mode;
      engine.reset(currentMode);
      _last = DateTime.now();
    });

    await _loadBest();
  }

  void _handleTap(TapDownDetails details) {
    if (engine.gameOver) return;

    final w = MediaQuery.of(context).size.width;
    final lane = inputController.resolveLane(
      tapX: details.localPosition.dx,
      screenWidth: w,
      fallbackLaneSelector: () => engine.pickBestLane(),
    );

    final beforeScore = engine.score;
    engine.handleLaneTap(lane);

    // Coins: +1 * multiplier per hit
    if (engine.score > beforeScore) {
      coins.add(1 * currentMode.coinMultiplier);
    }

    setState(() {});
  }

  Future<void> _finalizeRunIfNeeded() async {
    // Save high score for this mode
    bestForMode = await highScores.saveIfHigher(currentMode, engine.score);
    if (mounted) setState(() {});
  }

  void _restartRaw() {
    setState(() {
      engine.reset(currentMode);
      _last = DateTime.now();
    });
  }

  // Interstitial rule still exists: after 5 completed games.
  // We interpret "completed" as "ended and player presses Play Again."
  // Epic retry prompt happens first (prompt). If they decline or already used -> normal flow.
  Future<void> _playAgainWithInterstitialRule() async {
    await _finalizeRunIfNeeded();

    // interstitial pacing: every 5 losses/finishes (excluding ad retry continuation)
    // We approximate by counting restarts; simplest: show 1 ad every 5 Play Again taps.
    // (You can refine later.)
    _playAgainCount++;
    final shouldShow = (_playAgainCount % 5 == 0);

    if (!shouldShow) {
      _restartRaw();
      return;
    }

    await interstitials.showIfReady(onClosed: () {
      _restartRaw();
    });
  }

  int _playAgainCount = 0;

  @override
  Widget build(BuildContext context) {
    final snap = engine.snapshot();
    final bgWidget = bg.buildForStage(snap.stage);

    final skin = skins.selected;

    return Scaffold(
      body: BannerFrame(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleTap,
          child: Stack(
            children: [
              Positioned.fill(child: bgWidget),
              Positioned.fill(child: Container(color: Colors.black.withOpacity(0.20))),

              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 54),
                  child: Board(
                    laneCount: laneCount,
                    tiles: snap.tiles,
                    topZoneTop: _topZoneTop,
                    topZoneBottom: _topZoneBottom,
                    bottomZoneTop: _bottomZoneTop,
                    bottomZoneBottom: _bottomZoneBottom,
                    skin: skin,
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Hud(
                  score: snap.score,
                  best: bestForMode,
                  strikes: snap.strikes,
                  stage: snap.stage,
                  speed: snap.speed,
                  coins: coins.coins,
                  inputMode: inputMode,
                  onToggleInputMode: _toggleInputMode,
                  onOpenBackgrounds: _openBackgrounds,
                  onOpenSkins: _openSkins,
                  onOpenModes: _openModes,
                  modeLabel: currentMode.label,
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
                          Text(
                            currentMode == GameMode.epic ? 'EPIC FAILED' : 'GAME OVER',
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text('Mode: ${currentMode.label}', style: const TextStyle(fontSize: 18)),
                          Text('Score: ${snap.score}', style: const TextStyle(fontSize: 20)),
                          Text('Best: $bestForMode', style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _playAgainWithInterstitialRule,
                            child: const Text('Play Again'),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            inputMode == InputMode.laneTap ? 'Input: Lane Tap' : 'Input: Anywhere Tap',
                            style: TextStyle(color: Colors.white.withOpacity(0.85)),
                          ),
                          if (currentMode == GameMode.epic)
                            Text(
                              snap.epicRetryAvailable
                                ? 'Retry available (ad prompt)'
                                : 'One retry per run',
                              style: TextStyle(color: Colors.white.withOpacity(0.75)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
DART

###############################################################################
# lib/ui/hud.dart  (add mode label + open modes)
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
  final int coins;

  final String modeLabel;

  final InputMode inputMode;
  final VoidCallback onToggleInputMode;
  final VoidCallback onOpenBackgrounds;
  final VoidCallback onOpenSkins;
  final VoidCallback onOpenModes;

  const Hud({
    super.key,
    required this.score,
    required this.best,
    required this.strikes,
    required this.stage,
    required this.speed,
    required this.coins,
    required this.modeLabel,
    required this.inputMode,
    required this.onToggleInputMode,
    required this.onOpenBackgrounds,
    required this.onOpenSkins,
    required this.onOpenModes,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Text('Mode $modeLabel', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Text('Score $score'),
            const SizedBox(width: 10),
            Text('Best $best'),
            const SizedBox(width: 10),
            Text('Coins $coins'),
            const Spacer(),
            Text('Strikes $strikes'),
            const SizedBox(width: 10),
            Text('Stage $stage'),
            const SizedBox(width: 10),
            Text('Speed ${speed.toStringAsFixed(0)}'),
            IconButton(
              tooltip: 'Modes',
              onPressed: onOpenModes,
              icon: const Icon(Icons.sports_esports),
            ),
            IconButton(
              tooltip: 'Skins',
              onPressed: onOpenSkins,
              icon: const Icon(Icons.palette),
            ),
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

echo "✅ Modes upgrade applied: 5 strikes, Reverse unlock+2x coins+separate best, Epic unlock+3x coins+separate best, Epic ad-retry prompt (1/run)."
echo "➡️ Next: git add . && git commit -m \"Add game modes + epic retry\" && git push"
