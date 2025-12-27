import 'dart:math';

class HumiliationEngine {
  final Random _rng = Random();
  int _last = -1;

  final List<String> _strike = const [
    'Bold move.',
    'That felt rushed.',
    'Respectfully… no.',
    'You blinked.',
    'Optimistic tapping detected.',
    'TapRush is concerned.',
    'Your finger panicked.',
    'Skill issue (affectionate).',
  ];

  final List<String> _over = const [
    'Game over. Hydrate and try again.',
    'That was… a run.',
    'TapRush remembers.',
    'One more. You know you want to.',
  ];

  String strikeLine() => _pick(_strike);
  String gameOverLine() => _pick(_over);

  String _pick(List<String> lines) {
    var idx = _rng.nextInt(lines.length);
    if (lines.length > 1 && idx == _last) idx = (idx + 1) % lines.length;
    _last = idx;
    return lines[idx];
  }
}
