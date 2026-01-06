import 'models.dart';

class InputResult {
  final bool hit;
  final bool flicked;
  final HitGrade grade;
  final TapEntity? entity;

  const InputResult._({
    required this.hit,
    required this.flicked,
    required this.grade,
    required this.entity,
  });

  const InputResult.miss()
      : hit = false,
        flicked = false,
        grade = HitGrade.miss,
        entity = null;

  factory InputResult.hit({
    required TapEntity entity,
    required bool flicked,
    required HitGrade grade,
  }) {
    return InputResult._(
      hit: true,
      flicked: flicked,
      grade: grade,
      entity: entity,
    );
  }
}
