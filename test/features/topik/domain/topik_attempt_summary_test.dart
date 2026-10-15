import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

const _fill = TopikQuestionType.r2GrammarBlank;
const _topic = TopikQuestionType.r2AdTopic;

TopikAttemptAnswer _answer(
  int no, {
  int? selected,
  int correct = 1,
  int timeMs = 0,
  TopikQuestionType? type = _fill,
}) => TopikAttemptAnswer(
  questionNo: no,
  selectedIdx: selected,
  timeSpentMs: timeMs,
  answeredAt: selected == null ? null : DateTime.utc(2026, 10, 15),
  correctIdx: correct,
  points: 2,
  pointsEarned: selected == correct ? 2 : 0,
  questionType: type,
);

TopikAttemptDetail _detail(
  List<TopikAttemptAnswer> answers, {
  TopikAttemptStatus status = TopikAttemptStatus.completed,
}) {
  final correct = answers.where((a) => a.selectedIdx == a.correctIdx).length;
  final answered = answers.where((a) => a.selectedIdx != null).length;
  final completed = status == TopikAttemptStatus.completed;
  return TopikAttemptDetail(
    attempt: TopikAttempt(
      id: 'A',
      testId: 'T',
      level: TopikLevel.topik2,
      section: TopikSection.reading,
      round: 96,
      mode: TopikAttemptMode.practice,
      status: status,
      startedAt: DateTime.utc(2026, 10, 15),
      completedAt: completed ? DateTime.utc(2026, 10, 15, 1) : null,
      updatedAt: DateTime.utc(2026, 10, 15, 1),
      totalTimeMs: answers.fold(0, (s, a) => s + a.timeSpentMs),
      currentQuestionNo: 1,
      questionCount: answers.length,
      maxScore: answers.length * 2,
      score: completed ? correct * 2 : null,
      correctCount: completed ? correct : null,
      answeredCount: completed ? answered : null,
      contentVersion: 1,
    ),
    answers: answers,
  );
}

// BR-TOPIK-023, BR-TOPIK-024, spec §6.4.
void main() {
  test('figures, filters and the longest question', () {
    final summary = topikAttemptSummaryOf(
      _detail([
        _answer(1, selected: 1, timeMs: 3000),
        _answer(2, selected: 2, timeMs: 9000),
        _answer(3, timeMs: 9000),
        _answer(4, selected: 1, timeMs: 1000),
      ]),
    );
    expect(summary.score, 4);
    expect(summary.maxScore, 8);
    expect(summary.correctCount, 2);
    expect(summary.answeredCount, 3);
    expect(summary.unansweredCount, 1);
    expect(summary.accuracyPercent, 50);
    expect(
      summary.longest!.questionNo,
      2,
    ); // tie 9000 ms goes to the lower number
    expect(
      [
        for (final a in summary.answersFor(TopikAnswerFilter.wrong))
          a.questionNo,
      ],
      [2],
    );
    expect(
      [
        for (final a in summary.answersFor(TopikAnswerFilter.unanswered))
          a.questionNo,
      ],
      [3],
    );
    expect(summary.answersFor(TopikAnswerFilter.correct), hasLength(2));
    expect(summary.answersFor(TopikAnswerFilter.all), hasLength(4));
  });

  test('no time at all names no longest question', () {
    final summary = topikAttemptSummaryOf(_detail([_answer(1), _answer(2)]));
    expect(summary.longest, isNull);
  });

  test('per type, and the weakest among types with two questions', () {
    final summary = topikAttemptSummaryOf(
      _detail([
        _answer(1, selected: 1, type: _topic),
        _answer(2, selected: 2, type: _topic),
        _answer(3, selected: 1),
        _answer(4, selected: 1),
        _answer(5, selected: 1),
        _answer(6, selected: 2),
      ]),
    );
    expect(
      [for (final s in summary.typeStats) (s.type, s.correct, s.total)],
      [(_fill, 3, 4), (_topic, 1, 2)], // enum order: grammar blank first
    );
    expect(summary.weakestType, _topic); // 50% < 75%
  });

  test('a tie in accuracy goes to the type with more questions', () {
    final summary = topikAttemptSummaryOf(
      _detail([
        _answer(1, selected: 1, type: _topic),
        _answer(2, selected: 2, type: _topic),
        _answer(3, selected: 1),
        _answer(4, selected: 1),
        _answer(5, selected: 2),
        _answer(6, selected: 2),
      ]),
    );
    expect(summary.weakestType, _fill); // both 50%, fill has 4
  });

  test('no weakest type when no type has two questions or all are right', () {
    expect(
      topikAttemptSummaryOf(
        _detail([
          _answer(1, selected: 2, type: _topic),
          _answer(2, selected: 2),
        ]),
      ).weakestType,
      isNull,
    );
    expect(
      topikAttemptSummaryOf(
        _detail([_answer(1, selected: 1), _answer(2, selected: 1)]),
      ).weakestType,
      isNull,
    );
  });

  test('an unknown type is left out of the table', () {
    final summary = topikAttemptSummaryOf(
      _detail([_answer(1, selected: 1, type: null), _answer(2, selected: 1)]),
    );
    expect([for (final s in summary.typeStats) s.type], [_fill]);
  });

  test('an attempt in progress has no summary', () {
    expect(
      () => topikAttemptSummaryOf(
        _detail([_answer(1)], status: TopikAttemptStatus.inProgress),
      ),
      throwsArgumentError,
    );
  });
}
