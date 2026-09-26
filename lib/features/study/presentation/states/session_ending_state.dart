import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

/// The summary states of screen 21 V8 can reach (handoff 21).
enum SummaryOutcome {
  reviewFinished,
  learningFinished,
  leftEarly,
  interrupted,
  reset,
  schedulerChanged,
  contentDeleted,
  saveError,
}

/// The hero's tone (FE-A6 D14): the kit's ok, paused, ended and error.
enum SummaryTone { success, paused, ended, error }

/// How the session screen treats a session that is no longer open.
sealed class SessionEnding {
  const SessionEnding();
}

/// Show screen 21 in [outcome].
final class ShowSummary extends SessionEnding {
  const ShowSummary(this.outcome);

  final SummaryOutcome outcome;
}

/// Leave with a toast: a write came from a stale generation
/// (UC-STUDY-001 E4) — never a summary (handoff 21 ruling).
final class LeaveStale extends SessionEnding {
  const LeaveStale();
}

/// How [view] ended; null while it is open.
SessionEnding? sessionEndingOf(StudySessionView view) {
  final isLearning = view.kind == SessionKind.learning;
  return switch ((view.status, view.endReason)) {
    (SessionStatus.inProgress, _) => null,
    (SessionStatus.completed, _) => ShowSummary(
      isLearning
          ? SummaryOutcome.learningFinished
          : SummaryOutcome.reviewFinished,
    ),
    (_, SessionEndReason.staleGeneration) => const LeaveStale(),
    (_, SessionEndReason.userExit) => const ShowSummary(
      SummaryOutcome.leftEarly,
    ),
    (_, SessionEndReason.interrupted) => const ShowSummary(
      SummaryOutcome.interrupted,
    ),
    (_, SessionEndReason.schedulerReset) => const ShowSummary(
      SummaryOutcome.reset,
    ),
    (_, SessionEndReason.schedulerChanged) => const ShowSummary(
      SummaryOutcome.schedulerChanged,
    ),
    (_, SessionEndReason.contentDeleted) => const ShowSummary(
      SummaryOutcome.contentDeleted,
    ),
    // failed/persistence_error, and any end the schema's matrix forbids.
    (_, SessionEndReason.persistenceError || null) => const ShowSummary(
      SummaryOutcome.saveError,
    ),
  };
}

/// What each summary state draws, as the kit draws it.
extension SummaryOutcomeRules on SummaryOutcome {
  SummaryTone get tone => switch (this) {
    SummaryOutcome.reviewFinished ||
    SummaryOutcome.learningFinished => SummaryTone.success,
    SummaryOutcome.leftEarly ||
    SummaryOutcome.interrupted => SummaryTone.paused,
    SummaryOutcome.reset ||
    SummaryOutcome.schedulerChanged ||
    SummaryOutcome.contentDeleted => SummaryTone.ended,
    SummaryOutcome.saveError => SummaryTone.error,
  };

  /// The footer's "Study this deck" (kit: loaded, learning, large,
  /// leftEarly).
  bool get canStudyAgain => switch (this) {
    SummaryOutcome.reviewFinished ||
    SummaryOutcome.learningFinished ||
    SummaryOutcome.leftEarly => true,
    _ => false,
  };

  /// The hero's three stats: only the ok and paused tones draw them.
  bool get drawsStats => switch (tone) {
    SummaryTone.success || SummaryTone.paused => true,
    SummaryTone.ended || SummaryTone.error => false,
  };

  /// The facts card: every state but an algorithm change.
  bool get drawsFacts => this != SummaryOutcome.schedulerChanged;
}
