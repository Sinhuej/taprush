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

class TapRushColors {
  static const background = Color(0xFF050816);
  static const barA = Color(0xFF00F5A0);
  static const barB = Color(0xFF7B61FF);
  static const barC = Color(0xFFFF00E5);
  static const accent = Color(0xFFFFC857);
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
  int _activeBar = 1;

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
        _score += 5;
      } else {
        _score += 1;
      }
      _activeBar = _random.nextInt(3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatusText(),
            const SizedBox(height: 24),
            Expanded(child: _buildBars()),
            const SizedBox(height: 24),
            _buildBottomButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildMiniIcon(),
          const SizedBox(width: 12),
          _buildTitle(),
          const Spacer(),
          _buildScoreBox(),
        ],
      ),
    );
  }

  Widget _buildMiniIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            TapRushColors.barA,
            TapRushColors.barB,
            TapRushColors.barC,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.touch_app, color: Colors.white),
    );
  }

  Widget _buildTitle() {
    return Column(
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
    );
  }

  Widget _buildScoreBox() {
    return Column(
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
    );
  }

  Widget _buildStatusText() {
    String label;

    if (_state == GameState.ready) label = 'Tap START to begin';
    else if (_state == GameState.countdown) label = 'Get ready… $_countdown';
    else if (_state == GameState.playing) label = 'Time left: $_timeLeft';
    else label = 'Time\'s up! Final score: $_score';

    return Text(
      label,
      style: GoogleFonts.rubik(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildBars() {
    return Row(
      children: [
        Expanded(child: _buildBar(0, TapRushColors.barA)),
        const SizedBox(width: 12),
        Expanded(child: _buildBar(1, TapRushColors.barB)),
        const SizedBox(width: 12),
        Expanded(child: _buildBar(2, TapRushColors.barC)),
      ],
    );
  }

  Widget _buildBar(int index, Color color) {
    bool isActive = (_activeBar == index && _state == GameState.playing);

    return GestureDetector(
      onTap: () => _onBarTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(isActive ? 0.7 : 0.3),
              color,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.8),
                    blurRadius: 24,
                    spreadRadius: 2,
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
        child: Center(
          child: Icon(
            Icons.touch_app,
            size: isActive ? 42 : 32,
            color: TapRushColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    bool canStart = (_state == GameState.ready || _state == GameState.finished);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _gameTimer?.cancel();
              _countdownTimer?.cancel();
              setState(() {
                _state = GameState.ready;
                _score = 0;
                _timeLeft = gameDurationSeconds;
              });
            },
          ),
        ],
      ),
    );
  }
}
