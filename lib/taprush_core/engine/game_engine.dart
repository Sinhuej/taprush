InputResult onGesture(GestureSample gesture) {
  final g = _g;
  if (g == null || isGameOver) return const InputResult.miss();

  final res = input.resolve(
    g: g,
    entities: entities,
    gesture: gesture,
  );

  if (!res.hit || res.entity == null) return res;

  final target = res.entity!;
  if (target.consumed) return const InputResult.miss();

  target.consumed = true;
  entities.remove(target);

  if (target.isBomb) {
    if (res.flicked) {
      stats.coins += 10;
      stats.bombsFlicked++;

      if (stats.bombsFlicked % 20 == 0 &&
          stats.bonusLivesEarned < maxBonusLives) {
        stats.bonusLivesEarned++;
        stats.strikes = max(0, stats.strikes - 1);
      }
    } else {
      stats.onStrike();
    }
    return res;
  }

  if (res.grade == HitGrade.perfect) {
    stats.onPerfect(coinMult: 1);
  } else {
    stats.onGood(coinMult: 1);
  }

  return res;
}

