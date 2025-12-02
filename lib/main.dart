import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TapRushApp());
}

class TapRushApp extends StatelessWidget {
  const TapRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6B3D); // neon orange from icon
    const seed = Color(0xFF0A0E21); // dark navy background

    return MaterialApp(
      title: 'TapRush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed).copyWith(
          primary: primary,
          secondary: const Color(0xFF00E0FF), // teal accent
        ),
        scaffoldBackgroundColor: const Color(0xFF050816),
        textTheme: GoogleFonts.poppinsTextTheme(
          const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

enum Difficulty { easy, normal, insane }

extension DifficultyLabel on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.normal:
        return 'Normal';
      case Difficulty.insane:
        return 'Insane';
    }
  }

  double get baseSpeed {
    switch (this) {
      case Difficulty.easy:
        return 0.35; // slow
      case Difficulty.normal:
        return 0.55;
      case Difficulty.insane:
        return 0.8; // fast
    }
  }

  Duration get spawnInterval {
    switch (this) {
      case Difficulty.easy:
        return const Duration(milliseconds: 850);
      case Difficulty.normal:
        return const Duration(milliseconds: 650);
      case Difficulty.insane:
        return const Duration(milliseconds: 480);
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Difficulty _difficulty = Difficulty.normal;
  int _bestScore = 0;
  bool _loadingBest = true;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('bestScore') ?? 0;
      _loadingBest = false;
    });
  }

  void _updateBestScore(int newBest) {
    setState(() {
      _bestScore = newBest;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF050816),
                Color(0xFF0B1028),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                'TapRush',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: colors.secondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap the glowing bars in rhythm.\nStay in the zone, keep the streak alive!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              if (_loadingBest)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    Text(
                      'Best Score',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_bestScore',
                      style: GoogleFonts.poppins(
                        color: colors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              Text(
                'Select Difficulty',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: Difficulty.values.map((d) {
                  final selected = d == _difficulty;
                  return ChoiceChip(
                    label: Text(d.label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _difficulty = d;
                      });
                    },
                    selectedColor: colors.primary,
                    labelStyle: GoogleFonts.poppins(
                      color: selected ? Colors.black : Colors.white70,
                    ),
                    backgroundColor: const Color(0xFF14172F),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () async {
                    final result = await Navigator.of(context).push<int>(
                      MaterialPageRoute(
                        builder: (_) =>
                            GameScreen(difficulty: _difficulty),
                      ),
                    );
                    if (result != null && result > _bestScore) {
                      _updateBestScore(result);
                    }
                  },
                  child: Text(
                    'Start Run',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tip: Tap anywhere in a column when the bar crosses the bottom line.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Represents one falling bar
class NoteBar {
  NoteBar({
    required this.laneIndex,
    required this.y,
    required this.speed,
    this.hit = false,
  });

  final int laneIndex; // 0, 1, 2
  double y; // 0 = top, 1 = bottom
  double speed; // logical units per second
  bool hit;
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.difficulty});

  final Difficulty difficulty;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<NoteBar> _bars = [];
  late Timer _timer;
  final Random _random = Random();

  int _score = 0;
  int _combo = 0;
  int _misses = 0;
  int _bestCombo = 0;

  // Spawn control
  late Duration _spawnInterval;
  Duration _elapsedSinceSpawn = Duration.zero;

  // Game loop delta timing
  late DateTime _lastTick;

  // Hit feedback
  String _statusText = '';
  Color _statusColor = Colors.white;
  double _laneGlowOpacity = 0.0;
  int _glowLaneIndex = -1;

  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _spawnInterval = widget.difficulty.spawnInterval;
    _lastTick = DateTime.now();
    _startLoop();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startLoop() {
    // ~60fps-ish
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final now = DateTime.now();
      final dtSeconds =
          now.difference(_lastTick).inMilliseconds / 1000.0;
      _lastTick = now;
      _elapsedSinceSpawn += now.difference(now.subtract(
          Duration(milliseconds: (dtSeconds * 1000).round())));

      _updateBars(dtSeconds);
      _maybeSpawnBar();
    });
  }

  void _updateBars(double dt) {
    if (_isGameOver) return;

    bool shouldSetState = false;

    for (final bar in _bars) {
      bar.y += bar.speed * dt;
      if (bar.y > 1.1 && !bar.hit) {
        // Missed bar
        _registerMiss();
        bar.hit = true; // so we don’t double count
        shouldSetState = true;
      }
    }

    _bars.removeWhere((bar) => bar.y > 1.2);

    // Fade lane glow
    if (_laneGlowOpacity > 0) {
      _laneGlowOpacity = max(0, _laneGlowOpacity - dt * 2.5);
      shouldSetState = true;
    }

    if (shouldSetState) {
      setState(() {});
    } else {
      // Still need to repaint for movement
      setState(() {});
    }
  }

  void _maybeSpawnBar() {
    if (_isGameOver) return;

    _elapsedSinceSpawn += const Duration(milliseconds: 16);
    if (_elapsedSinceSpawn >= _spawnInterval) {
      _elapsedSinceSpawn = Duration.zero;
      final lane = _random.nextInt(3);
      final baseSpeed = widget.difficulty.baseSpeed;
      final extraSpeed = min(0.6, _score / 1200); // slight ramp-up
      final speed = baseSpeed + extraSpeed; // units per sec

      _bars.add(
        NoteBar(
          laneIndex: lane,
          y: -0.15, // start slightly above top
          speed: speed,
        ),
      );
    }
  }

  void _registerHit(NoteBar bar, {required bool perfect}) {
    bar.hit = true;
    _score += perfect ? 3 : 1;
    _combo += 1;
    _bestCombo = max(_bestCombo, _combo);

    _statusText = perfect ? 'PERFECT!' : 'GOOD';
    _statusColor = perfect ? Colors.greenAccent : Colors.yellowAccent;
  }

  void _registerMiss() {
    _combo = 0;
    _misses += 1;
    _statusText = 'MISS';
    _statusColor = Colors.redAccent;

    if (_misses >= 5) {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    if (_isGameOver) return;
    _isGameOver = true;
    _timer.cancel();

    // Save best score
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt('bestScore') ?? 0;
    if (_score > best) {
      await prefs.setInt('bestScore', _score);
    }

    if (mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: const Color(0xFF14172F),
            title: Text(
              'Run Over',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow('Score', _score),
                _statRow('Best combo', _bestCombo),
                _statRow('Misses', _misses),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(_score);
                },
                child: Text(
                  'Back',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _restartGame();
                },
                child: Text(
                  'Play Again',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _statRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _bars.clear();
      _score = 0;
      _combo = 0;
      _misses = 0;
      _bestCombo = 0;
      _statusText = '';
      _laneGlowOpacity = 0;
      _glowLaneIndex = -1;
      _isGameOver = false;
      _elapsedSinceSpawn = Duration.zero;
      _lastTick = DateTime.now();
    });

    _startLoop();
  }

  void _handleTap(Offset globalPos, BuildContext context) {
    if (_isGameOver) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = box.globalToLocal(globalPos);
    final width = box.size.width;
    final height = box.size.height;

    final laneWidth = width / 3;
    final laneIndex = (local.dx ~/ laneWidth).clamp(0, 2);
    const hitLine = 0.86; // 86% down the screen
    const perfectWindow = 0.035;
    const goodWindow = 0.08;

    NoteBar? bestBar;
    double bestDistance = 1.0;

    for (final bar in _bars) {
      if (bar.laneIndex != laneIndex || bar.hit) continue;
      final distance = (bar.y - hitLine).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestBar = bar;
      }
    }

    _glowLaneIndex = laneIndex;
    _laneGlowOpacity = 0.7;

    if (bestBar != null && bestDistance <= goodWindow) {
      final perfect = bestDistance <= perfectWindow;
      _registerHit(bestBar, perfect: perfect);
    } else {
      _registerMiss();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleTap(details.globalPosition, context),
          child: Column(
            children: [
              // Top HUD
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () {
                        _isGameOver = true;
                        _timer.cancel();
                        Navigator.of(context).pop(_score);
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'TapRush',
                      style: GoogleFonts.poppins(
                        color: colors.secondary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Score: $_score',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Combo: $_combo',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status text
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: AnimatedOpacity(
                  opacity: _statusText.isEmpty ? 0 : 1,
                  duration: const Duration(milliseconds: 120),
                  child: Text(
                    _statusText,
                    style: GoogleFonts.poppins(
                      color: _statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Miss indicators
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < _misses;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? Colors.redAccent : Colors.white24,
                      ),
                    );
                  }),
                ),
              ),
              // Game area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    final laneWidth = width / 3;

                    return Stack(
                      children: [
                        Row(
                          children: List.generate(3, (i) {
                            final isGlowLane = i == _glowLaneIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: laneWidth,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: i == 0
                                      ? BorderSide.none
                                      : BorderSide(
                                          color: Colors.white12, width: 1),
                                  right: BorderSide(
                                      color: Colors.white12, width: 1),
                                ),
                                gradient: isGlowLane
                                    ? LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(
                                              _laneGlowOpacity * 0.09),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : null,
                              ),
                            );
                          }),
                        ),
                        // Hit line
                        Positioned(
                          left: 0,
                          right: 0,
                          top: height * 0.86,
                          child: Container(
                            height: 2,
                            color: colors.primary.withOpacity(0.7),
                          ),
                        ),
                        // Bars
                        ..._bars.map((bar) {
                          final x = bar.laneIndex * laneWidth;
                          final y = bar.y * height;
                          final barColor = _laneColorForIndex(bar.laneIndex);

                          return Positioned(
                            left: x + laneWidth * 0.18,
                            width: laneWidth * 0.64,
                            top: y,
                            height: height * 0.16,
                            child: Opacity(
                              opacity: bar.hit ? 0.2 : 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: [
                                      barColor.withOpacity(0.95),
                                      barColor.withOpacity(0.55),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: barColor.withOpacity(0.7),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _laneColorForIndex(int lane) {
    switch (lane) {
      case 0:
        return const Color(0xFF00E0FF); // teal
      case 1:
        return const Color(0xFFB455FF); // purple
      case 2:
        return const Color(0xFFFF6B3D); // orange
      default:
        return Colors.white;
    }
  }
}
