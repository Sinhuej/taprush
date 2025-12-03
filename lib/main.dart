import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B2DFF), // purple from icon
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const TapRushGame(),
    );
  }
}

class TapRushGame extends StatefulWidget {
  const TapRushGame({super.key});

  @override
  State<TapRushGame> createState() => _TapRushGameState();
}

class _TapRushGameState extends State<TapRushGame> {
  static const int barCount = 4;
  static const double hitThreshold = 0.6; // how full a bar must be for HIT
  static const Duration tick = Duration(milliseconds: 120);

  final Random _rand = Random();

  late List<double> _fill; // 0.0–1.0 for each bar
  Timer? _timer;

  bool _running = false;
  int _score = 0;
  int _bestScore = 0;
  int _combo = 0;
  int _misses = 0;
  int _level = 1;

  int? _lastTapIndex;
  bool _lastTapHit = false;

  @override
  void initState() {
    super.initState();
    _resetGame(hard: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetGame({bool hard = false}) {
    _timer?.cancel();
    _fill = List<double>.filled(barCount, 0.2);
    _running = false;
    _combo = 0;
    _misses = 0;
    _level = hard ? 1 : _level;
    _lastTapIndex = null;
    _lastTapHit = false;
    if (hard) _score = 0;
    setState(() {});
  }

  void _startGame() {
    if (_running) return;
    _running = true;
    _timer?.cancel();
    _timer = Timer.periodic(tick, _onTick);
    setState(() {});
  }

  void _onTick(Timer timer) {
    setState(() {
      // Slowly drain bars
      for (int i = 0; i < barCount; i++) {
        _fill[i] = max(0, _fill[i] - 0.03);
      }

      // Randomly boost one bar
      final int i = _rand.nextInt(barCount);
      _fill[i] = min(1.0, _fill[i] + 0.18 + _level * 0.03);

      // Level up very slowly
      _level = 1 + _score ~/ 25;

      // Game over if all bars are empty for too long
      if (_fill.every((v) => v <= 0.05)) {
        _running = false;
        _timer?.cancel();
      }
    });
  }

  void _onBarTap(int index) {
    if (!_running) {
      // First tap starts the game
      _startGame();
    }

    final double value = _fill[index];
    final bool hit = value >= hitThreshold;

    setState(() {
      _lastTapIndex = index;
      _lastTapHit = hit;

      if (hit) {
        _combo++;
        _score += 5 + _combo; // reward streaks
        _fill[index] = max(0.0, value - 0.4); // drain bar on successful tap
      } else {
        _combo = 0;
        _misses++;
        _score = max(0, _score - 3);
      }

      if (_score > _bestScore) {
        _bestScore = _score;
      }
    });
  }

  Color _barColor(int index) {
    // Match icon-ish palette: purple, teal, pink, orange
    const List<Color> colors = [
      Color(0xFF7B2DFF),
      Color(0xFF00D9C0),
      Color(0xFFFF4FA3),
      Color(0xFFFFA726),
    ];
    return colors[index % colors.length];
  }

  Widget _buildBar(int index) {
    final double value = _fill[index];

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // <- IMPORTANT: register taps
        onTap: () => _onBarTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double height = constraints.maxHeight;
              final double filledHeight = height * value;

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Track
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  // Fill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    width: double.infinity,
                    height: max(4, filledHeight),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          _barColor(index),
                          _barColor(index).withOpacity(0.45),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _barColor(index).withOpacity(0.5 * value),
                          blurRadius: 14 * value,
                          spreadRadius: 2 * value,
                        ),
                      ],
                    ),
                  ),
                  // Hit zone marker
                  Positioned(
                    top: height * (1 - hitThreshold) - 2,
                    left: 6,
                    right: 6,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(0.28),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TapRush v2',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                _running ? 'Keep the beat… TAP!' : 'Tap any bar to start',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          _statChip('LV', '$_level'),
          const SizedBox(width: 6),
          _statChip('BEST', '$_bestScore'),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.9,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomHud() {
    String tapText = 'No taps yet';
    if (_lastTapIndex != null) {
      tapText =
          'Last tap: BAR ${_lastTapIndex! + 1} • ${_lastTapHit ? "HIT!" : "MISS"}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tapText,
            style: TextStyle(
              fontSize: 14,
              color: _lastTapIndex == null
                  ? Colors.white.withOpacity(0.75)
                  : (_lastTapHit ? Colors.greenAccent : Colors.redAccent),
              fontWeight:
                  _lastTapIndex == null ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Combo: $_combo',
                style: TextStyle(
                  fontSize: 14,
                  color: _combo > 1
                      ? Colors.lightBlueAccent
                      : Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Miss: $_misses',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _running ? _resetGame : _startGame,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: const Color(0xFF7B2DFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(_running ? 'Pause & Reset' : 'Start'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF140B33),
            Color(0xFF260F4F),
            Color(0xFF1B103B),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopHud(),
              const SizedBox(height: 6),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(barCount, _buildBar),
                  ),
                ),
              ),
              _buildBottomHud(),
            ],
          ),
        ),
      ),
    );
  }
}

