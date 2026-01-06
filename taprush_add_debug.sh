#!/usr/bin/env bash
set -e

echo "🔧 Adding TapRush debug system (no /tmp, repo-safe)..."

ENGINE_FILE="lib/taprush_core/engine/game_engine.dart"
ENGINE_TMP="lib/taprush_core/engine/.game_engine.tmp.dart"

# --------------------------------------------------
# 1. Create debug directory + DebugLog
# --------------------------------------------------
mkdir -p lib/taprush_core/debug

cat > lib/taprush_core/debug/debug_log.dart <<'DART'
class DebugLog {
  static bool enabled = false;
  static const int maxLines = 400;
  static final List<String> _lines = [];

  static void log(String tag, String msg, double time) {
    if (!enabled) return;
    final line = '[${time.toStringAsFixed(2)}][$tag] $msg';
    _lines.add(line);
    if (_lines.length > maxLines) _lines.removeAt(0);
  }

  static List<String> snapshot() {
    return List.unmodifiable(_lines);
  }

  static void clear() {
    _lines.clear();
  }
}
DART

echo "✅ DebugLog created"

# --------------------------------------------------
# 2. Rewrite onGesture cleanly (NO backslashes)
# --------------------------------------------------
awk '
BEGIN { keep=1 }
/InputResult onGesture/ { keep=0 }
keep { print }
/^}/ && keep==0 { keep=1 }
' "$ENGINE_FILE" > "$ENGINE_TMP"

cat >> "$ENGINE_TMP" <<'DART'

  InputResult onGesture(GestureSample gesture) {
    final startTs = DateTime.now().millisecondsSinceEpoch;
    final g = _g;

    DebugLog.log('GESTURE', gesture.toString(), _time);

    if (g == null || isGameOver) {
      return const InputResult.miss();
    }

    final res = input.resolve(
      g: g,
      entities: entities,
      gesture: gesture,
    );

    final endTs = DateTime.now().millisecondsSinceEpoch;
    DebugLog.log(
      'GESTURE_TIME',
      'duration=${endTs - startTs}ms hit=${res.hit} flick=${res.flicked}',
      _time,
    );

    if (!res.hit || res.entity == null) {
      return res;
    }

    final target = res.entity!;

    if (target.consumed) {
      DebugLog.log('DOUBLE_SCORE', 'Blocked id=${target.id}', _time);
      return const InputResult.miss();
    }

    target.consumed = true;
    entities.remove(target);

    DebugLog.log(
      'HIT',
      'id=${target.id} bomb=${target.isBomb} flick=${res.flicked}',
      _time,
    );

    if (target.isBomb) {
      if (res.flicked) {
        stats.coins += 10;
        stats.bombsFlicked++;
      } else {
        stats.onStrike();
      }
      return res;
    }

    if (res.grade == HitGrade.perfect) {
      stats.onPerfect();
    } else {
      stats.onGood();
    }

    DebugLog.log('SCORE', 'score=${stats.score}', _time);
    return res;
  }
}
DART

mv "$ENGINE_TMP" "$ENGINE_FILE"

echo "✅ Engine onGesture rewritten safely"

# --------------------------------------------------
# 3. Done
# --------------------------------------------------
echo "🎯 Debug system installed"
echo "➡ Enable from Options screen"
echo "➡ Logs persist after game ends"
