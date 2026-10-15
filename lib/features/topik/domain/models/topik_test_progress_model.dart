import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';

/// How many attempts Recent Attempts shows (BR-TOPIK-021).
const int topikRecentAttemptCount = 5;

/// The Overall Progress card of one test (BR-TOPIK-020, spec §6.1). Score
/// figures use completed attempts only; time and sessions use every attempt.
/// A figure with nothing to show is null.
final class TopikTestProgress {
  const TopikTestProgress({
    required this.sessions,
    required this.completed,
    required this.completionPercent,
    required this.accuracyPercent,
    required this.bestScore,
    required this.averageScore,
    required this.lastActivityAt,
    required this.totalTimeMs,
  });

  final int sessions;
  final int completed;
  final int? completionPercent;
  final int? accuracyPercent;
  final int? bestScore;
  final int? averageScore;
  final DateTime? lastActivityAt;
  final int totalTimeMs;

  /// No attempt at all: the card becomes an empty state with Start.
  bool get isEmpty => sessions == 0;
}

TopikTestProgress topikTestProgressOf(Iterable<TopikAttempt> attempts) {
  var sessions = 0;
  var totalTimeMs = 0;
  DateTime? lastActivityAt;
  final scores = <int>[];
  var correct = 0;
  var questions = 0;
  for (final attempt in attempts) {
    sessions++;
    totalTimeMs += attempt.totalTimeMs;
    if (lastActivityAt == null || attempt.updatedAt.isAfter(lastActivityAt)) {
      lastActivityAt = attempt.updatedAt;
    }
    final score = attempt.score;
    if (!attempt.isCompleted || score == null) continue;
    scores.add(score);
    correct += attempt.correctCount ?? 0;
    questions += attempt.questionCount;
  }
  return TopikTestProgress(
    sessions: sessions,
    completed: scores.length,
    completionPercent: _percent(scores.length, sessions),
    accuracyPercent: _percent(correct, questions),
    bestScore: scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b),
    averageScore: scores.isEmpty
        ? null
        : _roundHalfUp(scores.fold(0, (sum, s) => sum + s), scores.length),
    lastActivityAt: lastActivityAt,
    totalTimeMs: totalTimeMs,
  );
}

/// An attempt and its `#n`: its rank among the test's current attempts by
/// start time (BR-TOPIK-021).
final class TopikNumberedAttempt {
  const TopikNumberedAttempt({required this.attempt, required this.number});

  final TopikAttempt attempt;
  final int number;
}

/// [attempts] numbered from the oldest (`#1`), listed newest first. A tie in
/// start time goes to the id (UUID v7, creation order).
List<TopikNumberedAttempt> topikNumberedAttemptsOf(
  Iterable<TopikAttempt> attempts,
) {
  final oldestFirst = [...attempts]
    ..sort((a, b) {
      final byStart = a.startedAt.compareTo(b.startedAt);
      return byStart != 0 ? byStart : a.id.compareTo(b.id);
    });
  return [
    for (var i = oldestFirst.length - 1; i >= 0; i--)
      TopikNumberedAttempt(attempt: oldestFirst[i], number: i + 1),
  ];
}

/// [part] of [whole] as a whole percent, rounded half up; null when [whole]
/// is 0.
int? _percent(int part, int whole) =>
    whole == 0 ? null : _roundHalfUp(part * 100, whole);

int _roundHalfUp(int numerator, int denominator) =>
    (2 * numerator + denominator) ~/ (2 * denominator);
