import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';

TopikAttemptAnswer _answer({int? selected, int? correct}) => TopikAttemptAnswer(
  questionNo: 1,
  selectedIdx: selected,
  timeSpentMs: 0,
  answeredAt: selected == null ? null : DateTime.utc(2026, 10, 15),
  correctIdx: correct,
  points: correct == null ? null : 2,
  pointsEarned: correct == null ? null : (selected == correct ? 2 : 0),
  questionType: null,
);

void main() {
  test('status codes round-trip and an unknown code is an error', () {
    for (final status in TopikAttemptStatus.values) {
      expect(TopikAttemptStatus.fromCode(status.code), status);
    }
    expect(TopikAttemptMode.fromCode('practice'), TopikAttemptMode.practice);
    expect(() => TopikAttemptStatus.fromCode('paused'), throwsArgumentError);
    expect(() => TopikAttemptMode.fromCode('exam'), throwsArgumentError);
  });

  test('an answer has no status until its attempt is submitted', () {
    expect(_answer(selected: 2).status, isNull);
  });

  test('a submitted answer is correct, wrong or unanswered', () {
    expect(_answer(selected: 2, correct: 2).status, TopikAnswerStatus.correct);
    expect(_answer(selected: 1, correct: 2).status, TopikAnswerStatus.wrong);
    expect(_answer(correct: 2).status, TopikAnswerStatus.unanswered);
  });
}
