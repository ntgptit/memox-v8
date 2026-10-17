import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';

/// Test detail (screen 36): the test, its Overall Progress and every
/// attempt numbered, newest first (BR-TOPIK-020, BR-TOPIK-021). [test] is
/// null when the catalog no longer has it (BR-TOPIK-019).
final class TopikTestDetail {
  const TopikTestDetail({
    required this.test,
    required this.progress,
    required this.attempts,
  });

  final TopikTest? test;
  final TopikTestProgress progress;
  final List<TopikNumberedAttempt> attempts;

  /// The one attempt in progress on this device, if any (BR-TOPIK-011).
  TopikNumberedAttempt? get inProgress {
    for (final numbered in attempts) {
      if (!numbered.attempt.isCompleted) return numbered;
    }
    return null;
  }

  List<TopikNumberedAttempt> get recent =>
      attempts.take(topikRecentAttemptCount).toList();
}

/// Whether [test] is still the content [detail] was answered on: it exists,
/// has exactly the questions the attempt stored answers for, and every
/// question's group is in it, so a screen can look a question and its group up
/// without a miss (BR-TOPIK-019). The one check screens 37 and 39 share.
bool topikContentMatchesAttempt(TopikTest? test, TopikAttemptDetail detail) {
  if (test == null) return false;
  final stored = {for (final answer in detail.answers) answer.questionNo};
  final numbers = {for (final question in test.questions) question.no};
  if (stored.length != numbers.length || !stored.containsAll(numbers)) {
    return false;
  }
  final groupIds = {for (final group in test.groups) group.groupId};
  return test.questions.every(
    (question) => groupIds.contains(question.groupId),
  );
}

/// The attempt screen's data (screen 37); [test] null when unavailable.
final class TopikAttemptView {
  const TopikAttemptView({required this.detail, required this.test});

  final TopikAttemptDetail detail;
  final TopikTest? test;

  /// The attempt cannot go on: its test is gone, or no longer has exactly the
  /// attempt's questions and their groups (BR-TOPIK-019; the store refuses
  /// its submit then).
  bool get isContentMissing => !topikContentMatchesAttempt(test, detail);
}

/// Summary (screen 38): from the snapshot alone (BR-TOPIK-019). The hero
/// names the test from the attempt's own fields, so no content is read.
final class TopikSummaryView {
  const TopikSummaryView({required this.attempt, required this.summary});

  final TopikAttempt attempt;
  final TopikAttemptSummary summary;
}

/// Review (screen 39): the attempt over the current content
/// (BR-TOPIK-019).
final class TopikReviewView {
  const TopikReviewView({required this.detail, required this.test});

  final TopikAttemptDetail detail;
  final TopikTest? test;

  /// The test is gone or no longer fits the attempt (the same check as the
  /// attempt screen's): Review is unavailable, Summary still is
  /// (BR-TOPIK-019).
  bool get isUnavailable => !topikContentMatchesAttempt(test, detail);

  /// The content was updated after this attempt was scored.
  bool get isContentChanged =>
      test != null && test!.contentVersion != detail.attempt.contentVersion;
}
