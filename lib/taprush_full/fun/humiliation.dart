enum HumiliationEffect {
  hotDogFingers,
  squeakyTaps,
  upsideDownScore,
  cheaterOverlay,
  dadWatching,
  questionableSkill,
}

class HumiliationLine {
  final HumiliationEffect effect;
  final String text;
  const HumiliationLine(this.effect, this.text);
}

class HumiliationEngine {
  int _i = 0;

  HumiliationLine next() {
    final effects = HumiliationEffect.values;
    _i = (_i + 1) % effects.length;
    final e = effects[_i];

    switch (e) {
      case HumiliationEffect.hotDogFingers:
        return HumiliationLine(e, '🌭 Hot-dog fingers engaged.');
      case HumiliationEffect.squeakyTaps:
        return HumiliationLine(e, '🧸 Squeaky taps enabled. You did this.');
      case HumiliationEffect.upsideDownScore:
        return HumiliationLine(e, '🙃 Score feels… different now.');
      case HumiliationEffect.cheaterOverlay:
        return HumiliationLine(e, 'CHEATER MODE (UNRANKED)');
      case HumiliationEffect.dadWatching:
        return HumiliationLine(e, 'Dad’s watching.');
      case HumiliationEffect.questionableSkill:
        return HumiliationLine(e, 'Skill: Questionable.');
    }
  }
}
