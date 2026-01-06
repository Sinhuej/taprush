class DebugEvent {
  final double time;
  final String tag;
  final String message;

  DebugEvent(this.time, this.tag, this.message);
}

class DebugLog {
  static const int maxEvents = 300;
  static final List<DebugEvent> _events = [];

  static void log(String tag, String message, double time) {
    _events.add(DebugEvent(time, tag, message));
    if (_events.length > maxEvents) {
      _events.removeAt(0);
    }
  }

  static List<DebugEvent> snapshot() {
    return List.unmodifiable(_events);
  }

  static void clear() {
    _events.clear();
  }
}
