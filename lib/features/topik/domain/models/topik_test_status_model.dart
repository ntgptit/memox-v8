import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';

/// What the test list shows of a test the person has attempted
/// (BR-TOPIK-022): in progress, or the best score of its completed attempts
/// and how many there are. A test without attempts has no status: not
/// started.
final class TopikTestStatus {
  const TopikTestStatus({
    required this.testId,
    required this.hasInProgress,
    required this.completedCount,
    required this.bestScore,
    required this.lastActivityAt,
  });

  final String testId;
  final bool hasInProgress;
  final int completedCount;

  /// Null when no attempt is completed.
  final int? bestScore;

  /// The latest `updatedAt` of any attempt, for the "latest activity" sort.
  final DateTime lastActivityAt;
}

/// The status of each test [attempts] belong to, keyed by test id.
Map<String, TopikTestStatus> topikTestStatusesOf(
  Iterable<TopikAttempt> attempts,
) {
  final byTest = <String, List<TopikAttempt>>{};
  for (final attempt in attempts) {
    (byTest[attempt.testId] ??= []).add(attempt);
  }
  return {
    for (final MapEntry(key: testId, value: ofTest) in byTest.entries)
      testId: _statusOf(testId, ofTest),
  };
}

TopikTestStatus _statusOf(String testId, List<TopikAttempt> attempts) {
  var hasInProgress = false;
  var completedCount = 0;
  int? bestScore;
  var lastActivityAt = attempts.first.updatedAt;
  for (final attempt in attempts) {
    if (attempt.updatedAt.isAfter(lastActivityAt)) {
      lastActivityAt = attempt.updatedAt;
    }
    final score = attempt.score;
    if (!attempt.isCompleted || score == null) {
      hasInProgress = true;
      continue;
    }
    completedCount++;
    if (bestScore == null || score > bestScore) bestScore = score;
  }
  return TopikTestStatus(
    testId: testId,
    hasInProgress: hasInProgress,
    completedCount: completedCount,
    bestScore: bestScore,
    lastActivityAt: lastActivityAt,
  );
}
