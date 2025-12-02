import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TapRushApp());
}

class TapRushApp extends StatelessWidget {
  const TapRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapRush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: TapRushColors.background,
        textTheme: GoogleFonts.rubikTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: TapRushColors.accent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TapRushGameScreen(),
    );
  }
}

/// Colors inspired by the icon (Option 3)
class TapRushColors {
  static const background = Color(0xFF050816); // deep navy
  static const barA = Color(0xFF00F5A0); // aqua
  static const barB = Color(0xFF7B61FF); // purple
  static const barC = Color(0xFFFF00E5); // neon magenta
  static const accent = Color(0xFFFFC857); // golden finger color
  static const dimText = Color(0xFF9CA3AF);
}

enum GameState { ready, countdown, playing, finished }

class TapRushGameScreen extends StatefulWidget {
  const TapRushGameScreen({super.key});

  @override
  State<TapRushGameScreen> createState() => _TapRushGameScreenState();
}

class _TapRushGameScreenState extends State<TapRushGameScreen> {
  static const int gameDurationSeconds = 30;
  static const int countdownStart = 3;

  GameState _state = GameState.ready;
  int _score = 0;
  int _bestScore = 0;
  int _timeLeft = gameDurationSeconds;
  int _countdown = countdownStart;
  int _activeBar = 1; // 0,1,2 -> which bar is “glowing”
  Timer? _gameTimer;
  Timer? _countdownTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('best_score') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_score', _bestScore);
  }

  void _startCountdown() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();

    setState(() {
      _state = GameState.countdown;
      _score = 0;
      _timeLeft = gameDurationSeconds;
      _countdown = countdownStart;
      _activeBar = _random.nextInt(3);
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        _startGame();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _startGame() {
    _gameTimer?.cancel();

    setState(() {
      _state = GameState.playing;
      _timeLeft = gameDurationSeconds;
      _activeBar = _random.nextInt(3);
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        _timeLeft = max(0, _timeLeft - 1);
      });

      // every 1 second (5 ticks of 200ms), switch active bar
      if (timer.tick % 5 == 0) {
        setState(() {
          _activeBar = _random.nextInt(3);
        });
      }

      if (_timeLeft <= 0) {
        timer.cancel();
        _finishGame();
      }
    });
  }

  void _finishGame() {
    setState(() {
      _state = GameState.finished;
      if (_score > _bestScore) {
        _bestScore = _score;
        _saveBestScore();
      }
    });
  }

  void _onBarTapped(int index) {
    if (_state != GameState.playing) return;

    setState(() {
      if (index == _activeBar) {
        // Perfect tap on glowing bar
        _score += 5;
      } else {
        // Normal tap
        _score += 1;
      }
      // Shuffle active bar again after a tap
      _activeBar = _random.nextInt(3);
    });
  }

  String get _timeLabel {
    final seconds = (_timeLeft ~/ 5); // because we decrement 5x per second
    final clamped = max(0, min(seconds, gameDurationSeconds));
    final padded = clamped.toString().padLeft(2, '0');
    return '00:$padded';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatusText(),
              const SizedBox(height: 24),
              Expanded(child: _buildBars()),
              const SizedBox(height: 24),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // mini icon mimic
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                TapRushColors.barA,
                TapRushColors.barB,
                TapRushColors.barC,
              ],
            ),
          ),
          child: const Icon(Icons.touch_app, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TapRush',
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Tap fast. Hit the glowing bar.',
              style: GoogleFonts.rubik(
                fontSize: 12,
                color: TapRushColors.dimText,
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Score: $_score',
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Best: $_bestScore',
              style: GoogleFonts.rubik(
                fontSize: 12,
                color: TapRushColors.dimText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusText() {
    String label;
    switch (_state) {
      case GameState.ready:
        label = 'Tap START to begin';
        break;
      case GameState.countdown:
        label = 'Get ready… $_countdown';
        break;
      case GameState.playing:
        label = 'Time left: $_timeLabel';
        break;
      case GameState.finished:
        label = 'Time\'s up! Final score: $_score';
        break;
    }

    return Text(
      label,
      style: GoogleFonts.rubik(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBars() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBar(
          index: 0,
          baseColor: TapRushColors.barA,
        ),
        const SizedBox(width: 12),
        _buildBar(
          index: 1,
          baseColor: TapRushColors.barB,
        ),
        const SizedBox(width: 12),
        _buildBar(
          index: 2,
          baseColor: TapRushColors.barC,
        ),
      ],
    );
  }

  Widget _buildBar({
    required int index,
    required Color baseColor,
  }) {
    final bool isActive = _activeBar == index && _state == GameState.playing;
    final double glowStrength = isActive ? 1.0 : 0.0;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onBarTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                baseColor.withOpacity(0.35 + glowStrength * 0.25),
                baseColor.withOpacity(0.9),
              ],
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: baseColor.withOpacity(0.7),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // decorative bars
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Icon(
                    Icons.touch_app,
                    size: isActive ? 40 : 32,
                    color: TapRushColors.accent.withOpacity(
                      isActive ? 1.0 : 0.7,
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

  Widget _buildBottomButtons() {
    final bool canStart =
        _state == GameState.ready || _state == GameState.finished;

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: canStart ? _startCountdown : null,
            style: FilledButton.styleFrom(
              backgroundColor: TapRushColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(canStart ? 'START' : 'PLAYING…'),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            _gameTimer?.cancel();
            _countdownTimer?.cancel();
            setState(() {
              _state = GameState.ready;
              _score = 0;
              _timeLeft = gameDurationSeconds;
            });
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset',
        ),
      ],
    );
  }
}

