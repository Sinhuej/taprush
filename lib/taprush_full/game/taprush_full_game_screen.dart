import 'dart:math';
import 'package:flutter/material.dart';

import '../app/app_state.dart';

import 'modes/mode_stack.dart';
import 'modes/tap_intent.dart';
import 'modes/normal_mode.dart';
import 'modes/reverse_mode.dart';
import 'modes/dual_mode.dart';
import 'modes/sideways_mode.dart';
import 'modes/chaos_mode.dart';
import 'modes/mode_id.dart';
import 'modes/device_lock.dart';

import '../platform/orientation_util.dart';
import 'sideways_cheat_bridge.dart';

import '../fun/humiliation.dart';

import '../../anti_cheat/cheat_sequence.dart';
import '../../anti_cheat/cheat_detector.dart';

class TapRushFullGameScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onOpenStore;
  final VoidCallback onStateChanged;

  const TapRushFullGameScreen({
    super.key,
    required this.state,
    required this.onOpenStore,
    required this.onStateChanged,
  });

  @override
  State<TapRushFullGameScreen> createState() => _TapRushFullGameScreenState();
}

class _TapRushFullGameScreenState extends State<TapRushFullGameScreen> with WidgetsBindingObserver {
  final _rng = Random();

  late final CheatSequence _cheatSequence;
  late final CheatDetector _cheatDetector;
  late final SidewaysCheatBridge _cheatBridge;

  final HumiliationEngine _humiliation = HumiliationEngine();
  HumiliationLine? _lastHumiliation;

  ModeId _selected = ModeId.normal;
  late ModeStack _stack;

  int _score = 0;
  int _lives = 3;

  TapIntent _rawRequired = TapIntent.up;
  TapIntent _required = TapIntent.up;
  TapIntent? _second; // dual second step

  bool get _isCheater => _cheatDetector.hasTriggered;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cheatSequence = CheatSequence();
    _cheatDetector = CheatDetector(visuals: _cheatSequence);
    _cheatBridge = SidewaysCheatBridge(_cheatDetector);

    _rebuildStack();
    _nextPrompt();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _checkOrientationCheat();
  }

  void _checkOrientationCheat() {
    if (!mounted) return;
    final current = simpleOrientationOf(context);
    _cheatBridge.check(lock: _stack.deviceLock, current: current);

    if (_isCheater) {
      _lastHumiliation ??= _humiliation.next();
    }
  }

  void _rebuildStack() {
    final modes = <dynamic>[NormalMode()];

    switch (_selected) {
      case ModeId.normal:
        break;
      case ModeId.reverse:
        modes.add(ReverseMode());
        break;
      case ModeId.dual:
        modes.add(DualMode());
        break;
      case ModeId.sideways:
        modes.add(SidewaysMode());
        break;
      case ModeId.chaos:
        modes.add(ChaosMode());
        modes.add(ReverseMode());
        modes.add(DualMode());
        modes.add(SidewaysMode());
        break;
    }

    _stack = ModeStack(modes.cast());
    _cheatDetector.reset();
    _lastHumiliation = null;
  }

  void _unlockLadder() {
    // Simple, deterministic ladder (swap with real progression later)
    if (_score >= 10) widget.state.unlockMode(ModeId.reverse);
    if (_score >= 25) widget.state.unlockMode(ModeId.dual);
    if (_score >= 40) widget.state.unlockMode(ModeId.sideways);
    if (_score >= 60) widget.state.unlockMode(ModeId.chaos);
  }

  void _nextPrompt() {
    _rawRequired = TapIntent.values[_rng.nextInt(4)];
    _required = _stack.transformRequired(_rawRequired);

    if (_stack.isDual) {
      // Dual: require up/down pair (2 steps)
      final a = _rng.nextBool() ? TapIntent.up : TapIntent.down;
      final b = a == TapIntent.up ? TapIntent.down : TapIntent.up;
      _required = _stack.transformRequired(a);
      _second = _stack.transformRequired(b);
    } else {
      _second = null;
    }
  }

  void _fail() {
    setState(() {
      _lives--;
      if (_lives <= 0) {
        widget.state.best = max(widget.state.best, _score);
        _score = 0;
        _lives = 3;
        _selected = ModeId.normal;
        widget.state.unlockedModes
          ..clear()
          ..add(ModeId.normal);
        _rebuildStack();
      }
      _nextPrompt();
    });
    widget.onStateChanged();
  }

  void _success() {
    setState(() {
      _score++;
      widget.state.best = max(widget.state.best, _score);
      _unlockLadder();
      _nextPrompt();
    });
    widget.onStateChanged();
  }

  void _tap(TapIntent tapped) {
    _checkOrientationCheat();

    // Cheater mode = playable, but humiliating tax.
    if (_isCheater) {
      _lastHumiliation ??= _humiliation.next();
      if (_rng.nextInt(4) == 0) {
        _fail();
        return;
      }
    }

    if (_stack.isDual) {
      final needA = _required;
      final needB = _second!;
      if (tapped == needA) {
        setState(() {
          _required = needB;
          _second = TapIntent.neutral; // marker: waiting for step 2
        });
        return;
      }
      if (_second == TapIntent.neutral && tapped == needB) {
        _success();
        return;
      }
      _fail();
      return;
    }

    if (tapped == _required) {
      _success();
    } else {
      _fail();
    }
  }

  Widget _modeChip(ModeId id, String label) {
    final unlocked = widget.state.unlockedModes.contains(id);
    final selected = _selected == id;

    return GestureDetector(
      onTap: unlocked
          ? () {
              setState(() {
                _selected = id;
                _rebuildStack();
                _nextPrompt();
              });
              widget.onStateChanged();
            }
          : null,
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(width: 2),
            color: selected ? Colors.black12 : Colors.transparent,
          ),
          child: Text(
            unlocked ? label : '$label 🔒',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _btn(TapIntent intent, String label, IconData icon) {
    final cheater = _isCheater;
    final displayLabel = cheater ? '🌭 $label' : label;

    return Expanded(
      child: GestureDetector(
        onTap: () => _tap(intent),
        child: Container(
          height: 90,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 6),
              Text(displayLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _checkOrientationCheat();

    final rotation = _stack.uiRotationDegrees;
    final lock = _stack.deviceLock;

    final prompt = _stack.isDual
        ? 'DUAL: hit ${_required.name.toUpperCase()} then (next)'
        : 'HIT: ${_required.name.toUpperCase()}';

    final lockText = lock == DeviceLock.portraitOnly
        ? 'Sideways rule: DO NOT rotate phone to landscape.'
        : '';

    final cheaterBanner = _isCheater
        ? (_lastHumiliation?.text ?? 'CHEATER MODE (UNRANKED)')
        : null;

    final playfield = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(prompt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (lockText.isNotEmpty)
          Text(lockText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(children: [
          _btn(TapIntent.left, 'LEFT', Icons.arrow_back),
          _btn(TapIntent.up, 'UP', Icons.arrow_upward),
        ]),
        Row(children: [
          _btn(TapIntent.down, 'DOWN', Icons.arrow_downward),
          _btn(TapIntent.right, 'RIGHT', Icons.arrow_forward),
        ]),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('TapRush'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: widget.onOpenStore,
            tooltip: 'Store',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Transform.rotate(
              angle: rotation * 3.1415926535 / 180.0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: playfield,
              ),
            ),
          ),

          Positioned(
            top: 18,
            left: 18,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score: $_score', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Best: ${widget.state.best}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Lives: $_lives', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Positioned(
            bottom: 18,
            left: 18,
            right: 18,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _modeChip(ModeId.normal, 'Normal'),
                _modeChip(ModeId.reverse, 'Reverse'),
                _modeChip(ModeId.dual, 'Dual'),
                _modeChip(ModeId.sideways, 'Sideways'),
                _modeChip(ModeId.chaos, 'Chaos'),
              ],
            ),
          ),

          if (cheaterBanner != null)
            Positioned(
              top: 64,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(width: 2, color: Colors.redAccent),
                    color: Colors.black.withOpacity(0.06),
                  ),
                  child: Text(
                    cheaterBanner,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
