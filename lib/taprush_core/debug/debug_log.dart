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
