import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_score_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/topik_content_fixtures.dart';

// BR-TOPIK-013, spec §5.3. Fixture: TOPIK I listening, questions 1–30,
// 1–10 worth 4 and 11–30 worth 3; the answer of question n is (n - 1) % 4 + 1.
void main() {
  final test1 = topikTestFixture(
    level: TopikLevel.topik1,
    section: TopikSection.listening,
  );
  Map<int, int?> blank() => {for (var no = 1; no <= 30; no++) no: null};

  test('scores correct, wrong and unanswered questions', () {
    final selections = blank()
      ..[1] =
          1 // correct, 4 points
      ..[2] =
          1 // wrong (answer 2)
      ..[11] = 3; // correct, 3 points

    final score = scoreTopikAttempt(test1, selections);

    expect(score.score, 7);
    expect(score.maxScore, 100);
    expect(score.correctCount, 2);
    expect(score.answeredCount, 3);
    expect(score.questionCount, 30);
    final byNo = {for (final a in score.answers) a.questionNo: a};
    expect(byNo[1]!.status, TopikAnswerStatus.correct);
    expect(byNo[1]!.pointsEarned, 4);
    expect(byNo[2]!.status, TopikAnswerStatus.wrong);
    expect(byNo[2]!.pointsEarned, 0);
    expect(byNo[2]!.correctIdx, 2);
    expect(byNo[3]!.status, TopikAnswerStatus.unanswered);
    expect(byNo[3]!.pointsEarned, 0);
    expect(byNo[3]!.points, 4);
    expect(byNo[11]!.questionType, TopikQuestionType.l1Topic);
  });

  test('answers come in question order', () {
    final score = scoreTopikAttempt(test1, blank());
    expect(score.answers.map((a) => a.questionNo), [
      for (var no = 1; no <= 30; no++) no,
    ]);
  });

  test('every answer right scores max_score; none answered scores 0', () {
    final all = {for (final q in test1.questions) q.no: q.answerIdx};
    final full = scoreTopikAttempt(test1, all);
    expect(full.score, full.maxScore);
    expect(full.correctCount, 30);

    final none = scoreTopikAttempt(test1, blank());
    expect(none.score, 0);
    expect(none.answeredCount, 0);
    expect(none.correctCount, 0);
  });

  test('TOPIK I reading keeps its real numbers 31–70', () {
    final reading = topikTestFixture(level: TopikLevel.topik1);
    final score = scoreTopikAttempt(reading, {
      for (var no = 31; no <= 70; no++) no: null,
    });
    expect(score.answers.first.questionNo, 31);
    expect(score.answers.last.questionNo, 70);
  });

  test('selections that are not exactly the test questions are an error', () {
    expect(
      () => scoreTopikAttempt(test1, blank()..remove(30)),
      throwsArgumentError,
    );
    expect(
      () => scoreTopikAttempt(test1, blank()..[31] = null),
      throwsArgumentError,
    );
  });
}
