import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';

TopikAttempt _attempt(
  String id,
  String testId, {
  int? score,
  required DateTime updatedAt,
}) {
  final completed = score != null;
  return TopikAttempt(
    id: id,
    testId: testId,
    level: TopikLevel.topik2,
    section: TopikSection.reading,
    round: 96,
    mode: TopikAttemptMode.practice,
    status: completed
        ? TopikAttemptStatus.completed
        : TopikAttemptStatus.inProgress,
    startedAt: DateTime.utc(2026, 10, 1),
    completedAt: completed ? updatedAt : null,
    updatedAt: updatedAt,
    totalTimeMs: 0,
    currentQuestionNo: 1,
    questionCount: 50,
    maxScore: 100,
    score: score,
    correctCount: score == null ? null : score ~/ 2,
    answeredCount: completed ? 50 : null,
    contentVersion: 1,
  );
}

// BR-TOPIK-022, spec §6.3.
void main() {
  test('a test without attempts has no status (not started)', () {
    expect(topikTestStatusesOf(const []), isEmpty);
  });

  test('folds the attempts of each test', () {
    final statuses = topikTestStatusesOf([
      _attempt('a1', 'A', score: 60, updatedAt: DateTime.utc(2026, 10, 2)),
      _attempt('a2', 'A', score: 80, updatedAt: DateTime.utc(2026, 10, 3)),
      _attempt('a3', 'A', updatedAt: DateTime.utc(2026, 10, 5)),
      _attempt('b1', 'B', updatedAt: DateTime.utc(2026, 10, 4)),
    ]);

    final a = statuses['A']!;
    expect(a.hasInProgress, isTrue);
    expect(a.completedCount, 2);
    expect(a.bestScore, 80);
    expect(a.lastActivityAt, DateTime.utc(2026, 10, 5));

    final b = statuses['B']!;
    expect(b.hasInProgress, isTrue);
    expect(b.completedCount, 0);
    expect(b.bestScore, isNull);
    expect(b.lastActivityAt, DateTime.utc(2026, 10, 4));
  });
}
