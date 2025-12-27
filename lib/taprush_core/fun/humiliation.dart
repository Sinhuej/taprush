import 'dart:math';

class HumiliationEngine {
  final Random _rng = Random();
  int _lastIdx = -1;

  final List<String> _strikeLines = const [
    'Bold move.',
    'That felt rushed.',
    'Who taught you that?',
    'Respectfully… no.',
    'You ok?',
    'That tile didn’t deserve that.',
    'You blinked.',
    'Skill issue (affectionate).',
    'We call that “optimistic tapping.”',
    'Your finger panicked. Understandable.',
  ];

  final List<String> _gameOverLines = const [
    'Game over. Hydrate and try again.',
    'You fought bravely. Incorrectly, but bravely.',
    'That was… a run.',
    'TapRush remembers. TapRush forgives. (Eventually.)',
    'One more. You know you want to.',
  ];

  String strikeLine() => _pick(_strikeLines);
  String gameOverLine() => _pick(_gameOverLines);

  String _pick(List<String> lines) {
    if (lines.isEmpty) return '';
    var idx = _rng.nextInt(lines.length);
    if (lines.length > 1 && idx == _lastIdx) {
      idx = (idx + 1) % lines.length;
    }
    _lastIdx = idx;
    return lines[idx];
  }
}
