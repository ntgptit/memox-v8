import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_group_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';

import '../../../support/topik_content_fixtures.dart';

TopikAttemptDetail _detailOf(TopikTest test) => TopikAttemptDetail(
  attempt: TopikAttempt(
    id: 'A',
    testId: test.testId,
    level: test.level,
    section: test.section,
    round: test.round,
    mode: TopikAttemptMode.practice,
    status: TopikAttemptStatus.completed,
    startedAt: DateTime.utc(2026, 10, 15),
    completedAt: DateTime.utc(2026, 10, 15, 1),
    updatedAt: DateTime.utc(2026, 10, 15, 1),
    totalTimeMs: 0,
    currentQuestionNo: 1,
    questionCount: test.questions.length,
    maxScore: 100,
    score: 0,
    correctCount: 0,
    answeredCount: 0,
    contentVersion: test.contentVersion,
  ),
  answers: [
    for (final question in test.questions)
      TopikAttemptAnswer(
        questionNo: question.no,
        selectedIdx: null,
        timeSpentMs: 0,
        answeredAt: null,
        correctIdx: question.answerIdx,
        points: question.points,
        pointsEarned: 0,
        questionType: question.questionType,
      ),
  ],
);

TopikTest _with(
  TopikTest test, {
  List<TopikQuestion>? questions,
  List<TopikQuestionGroup>? groups,
}) => TopikTest(
  schemaVersion: test.schemaVersion,
  contentVersion: test.contentVersion,
  testId: test.testId,
  level: test.level,
  round: test.round,
  section: test.section,
  format: test.format,
  form: test.form,
  titleKo: test.titleKo,
  officialTimeLimitSec: test.officialTimeLimitSec,
  source: test.source,
  groups: groups ?? test.groups,
  questions: questions ?? test.questions,
);

// BR-TOPIK-019: one check, shared by the attempt (37) and Review (39), that
// a question and its group can be looked up without a miss.
void main() {
  final content = topikTestFixture();
  final detail = _detailOf(content);

  test('the test the attempt was answered on matches', () {
    expect(topikContentMatchesAttempt(content, detail), isTrue);
    expect(
      TopikAttemptView(detail: detail, test: content).isContentMissing,
      false,
    );
    expect(TopikReviewView(detail: detail, test: content).isUnavailable, false);
  });

  test('a test that is gone does not match', () {
    expect(topikContentMatchesAttempt(null, detail), isFalse);
    expect(TopikReviewView(detail: detail, test: null).isUnavailable, isTrue);
  });

  test('a dropped question does not match', () {
    final dropped = _with(
      content,
      questions: content.questions.skip(1).toList(),
    );

    expect(topikContentMatchesAttempt(dropped, detail), isFalse);
    expect(
      TopikAttemptView(detail: detail, test: dropped).isContentMissing,
      true,
    );
    expect(TopikReviewView(detail: detail, test: dropped).isUnavailable, true);
  });

  test('a question added to the test does not match', () {
    final fewer = _detailOf(
      _with(content, questions: content.questions.skip(1).toList()),
    );

    expect(topikContentMatchesAttempt(content, fewer), isFalse);
  });

  test('a question whose group is missing does not match', () {
    final orphaned = _with(content, groups: content.groups.skip(1).toList());

    expect(topikContentMatchesAttempt(orphaned, detail), isFalse);
    expect(TopikReviewView(detail: detail, test: orphaned).isUnavailable, true);
  });
}
