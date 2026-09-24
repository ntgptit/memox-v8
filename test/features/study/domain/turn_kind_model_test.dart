import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

void main() {
  test("a card's first turn in a stage is learning in a learning session and "
      'scheduled in a review (BR-STUDY-023, BR-SRS-016)', () {
    expect(
      turnKindOf(SessionKind.learning, round: 1, answersInSession: 0),
      ReviewKind.learning,
    );
    expect(
      turnKindOf(SessionKind.reviewing, round: 1, answersInSession: 0),
      ReviewKind.scheduled,
    );
  });

  test('every later turn is relearning: a comeback, a retry, a next round '
      '(BR-SRS-017; spec D8)', () {
    for (final session in SessionKind.values) {
      expect(
        turnKindOf(session, round: 1, answersInSession: 1),
        ReviewKind.relearning,
      );
      expect(
        turnKindOf(session, round: 2, answersInSession: 0),
        ReviewKind.relearning,
      );
    }
  });
}
