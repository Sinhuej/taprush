import '../ui/start_overlay.dart';
import '../game/game_phase.dart';
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
  void startGame() {
    setState(() {
      phase = GamePhase.playing;
      strikes = 0;
      score = 0;
      stage = 0;
    });
  }

  State<TapRushGameScreen> createState() => _TapRushGameScreenState();
}

class _TapRushGameScreenState extends State<TapRushGameScreen> {
  GamePhase phase = GamePhase.idle;

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
  void startGame() {
    setState(() {
      phase = GamePhase.playing;
      strikes = 0;
      score = 0;
      stage = 0;
    });
  }

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
  void startGame() {
    setState(() {
      phase = GamePhase.playing;
      strikes = 0;
      score = 0;
      stage = 0;
    });
  }

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
  void startGame() {
    setState(() {
      phase = GamePhase.playing;
      strikes = 0;
      score = 0;
      stage = 0;
    });
  }

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
