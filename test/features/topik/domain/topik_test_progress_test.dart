import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';

TopikAttempt _attempt(
  String id, {
  required int startedMinute,
  int? score,
  int correct = 0,
  int timeMs = 0,
  bool? isCompleted,
}) {
  final started = DateTime.utc(2026, 10, 15, 9, startedMinute);
  final completed = isCompleted ?? score != null;
  return TopikAttempt(
    id: id,
    testId: 'T',
    level: TopikLevel.topik2,
    section: TopikSection.reading,
    round: 96,
    mode: TopikAttemptMode.practice,
    status: completed
        ? TopikAttemptStatus.completed
        : TopikAttemptStatus.inProgress,
    startedAt: started,
    completedAt: completed ? started.add(const Duration(minutes: 1)) : null,
    updatedAt: started.add(const Duration(minutes: 1)),
    totalTimeMs: timeMs,
    currentQuestionNo: 1,
    questionCount: 50,
    maxScore: 100,
    score: score,
    correctCount: completed ? correct : null,
    answeredCount: completed ? 50 : null,
    contentVersion: 1,
  );
}

// BR-TOPIK-020, BR-TOPIK-021, spec §6.1–§6.2.
void main() {
  test('no attempt is the empty state', () {
    final progress = topikTestProgressOf(const []);
    expect(progress.isEmpty, isTrue);
    expect(progress.sessions, 0);
    expect(progress.totalTimeMs, 0);
    expect(progress.bestScore, isNull);
  });

  test('only an attempt in progress has no score figures', () {
    final progress = topikTestProgressOf([
      _attempt('a', startedMinute: 0, timeMs: 5000),
    ]);
    expect(progress.sessions, 1);
    expect(progress.completed, 0);
    expect(progress.completionPercent, 0);
    expect(progress.accuracyPercent, isNull);
    expect(progress.bestScore, isNull);
    expect(progress.averageScore, isNull);
    expect(progress.totalTimeMs, 5000);
  });

  test('scores use completed attempts only; time uses every attempt', () {
    final progress = topikTestProgressOf([
      _attempt('a', startedMinute: 0, score: 60, correct: 30, timeMs: 1000),
      _attempt('b', startedMinute: 1, score: 81, correct: 41, timeMs: 2000),
      _attempt('c', startedMinute: 2, timeMs: 4000),
    ]);
    expect(progress.sessions, 3);
    expect(progress.completed, 2);
    expect(progress.completionPercent, 67); // 66.7 rounds half up
    expect(progress.accuracyPercent, 71); // 71 / 100
    expect(progress.bestScore, 81);
    expect(progress.averageScore, 71); // 70.5 rounds half up
    expect(progress.lastActivityAt, DateTime.utc(2026, 10, 15, 9, 3));
    expect(progress.totalTimeMs, 7000);
  });

  test('numbers follow start order, ties by id; the list is newest first', () {
    final numbered = topikNumberedAttemptsOf([
      _attempt('b', startedMinute: 0),
      _attempt('c', startedMinute: 5),
      _attempt('a', startedMinute: 0),
    ]);
    expect(
      [for (final n in numbered) (n.attempt.id, n.number)],
      [('c', 3), ('b', 2), ('a', 1)],
    );
  });

  test('deleting an attempt renumbers the rest', () {
    final numbered = topikNumberedAttemptsOf([
      _attempt('b', startedMinute: 1),
      _attempt('c', startedMinute: 2),
    ]);
    expect([for (final n in numbered) n.number], [2, 1]);
  });

  test('the score trend takes the scored attempts, oldest first: an attempt '
      'in progress or submitted without a score is no point, as it is no '
      'score in Best (follow-ups spec G8, final review F4)', () {
    final attempts = [
      _attempt('a', startedMinute: 0, score: 40),
      _attempt('b', startedMinute: 1, isCompleted: true),
      _attempt('c', startedMinute: 2, score: 70),
      _attempt('d', startedMinute: 3),
    ];
    final numbered = topikNumberedAttemptsOf(attempts);

    final scored = topikScoredAttemptsOf(numbered);
    expect([for (final n in scored) n.number], [1, 3]);
    expect([for (final n in scored) n.attempt.score], [40, 70]);
    expect(topikTestProgressOf(attempts).bestScore, 70);
    expect(topikTestProgressOf(attempts).completed, 2);
  });
}
