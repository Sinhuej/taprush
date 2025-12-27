enum CheatType {
  orientationManipulation,
}

class CheatEvent {
  final CheatType type;
  final String reason;
  final DateTime at;

  CheatEvent({
    required this.type,
    required this.reason,
  }) : at = DateTime.now();
}
