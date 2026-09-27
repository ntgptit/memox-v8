import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// Handoff 21's states; UC-STUDY-001 steps 13, A3, E3, E4.

StudySessionView _view(
  SessionStatus status, {
  SessionEndReason? reason,
  SessionKind kind = SessionKind.reviewing,
}) => StudySessionView(
  sessionId: 's',
  deckId: 'd',
  deckName: 'Nhà hàng',
  kind: kind,
  status: status,
  endReason: reason,
  currentMode: StudyMode.recall,
  direction: null,
  stages: const [StudyMode.recall],
  currentItem: null,
  progress: null,
  summary: status == SessionStatus.inProgress
      ? null
      : const SessionSummary(
          cardCount: 3,
          learnedCardCount: null,
          wrongTurnCount: 1,
          answeredCardCount: 2,
          turnCount: 3,
        ),
);

SummaryOutcome? _outcome(StudySessionView view) =>
    switch (sessionEndingOf(view)) {
      ShowSummary(:final outcome) => outcome,
      _ => null,
    };

void main() {
  test('an open session has no ending', () {
    expect(sessionEndingOf(_view(SessionStatus.inProgress)), isNull);
  });

  test('every end V8 can reach maps to its summary state', () {
    expect(
      _outcome(_view(SessionStatus.completed)),
      SummaryOutcome.reviewFinished,
    );
    expect(
      _outcome(_view(SessionStatus.completed, kind: SessionKind.learning)),
      SummaryOutcome.learningFinished,
    );
    for (final (status, reason, outcome) in [
      (
        SessionStatus.abandoned,
        SessionEndReason.userExit,
        SummaryOutcome.leftEarly,
      ),
      (
        SessionStatus.abandoned,
        SessionEndReason.interrupted,
        SummaryOutcome.interrupted,
      ),
      (
        SessionStatus.invalidated,
        SessionEndReason.schedulerReset,
        SummaryOutcome.reset,
      ),
      (
        SessionStatus.invalidated,
        SessionEndReason.schedulerChanged,
        SummaryOutcome.schedulerChanged,
      ),
      (
        SessionStatus.invalidated,
        SessionEndReason.contentDeleted,
        SummaryOutcome.contentDeleted,
      ),
      (
        SessionStatus.failed,
        SessionEndReason.persistenceError,
        SummaryOutcome.saveError,
      ),
    ]) {
      expect(
        _outcome(_view(status, reason: reason)),
        outcome,
        reason: '$reason',
      );
    }
  });

  test('a stale generation leaves, with no summary (UC-STUDY-001 E4)', () {
    expect(
      sessionEndingOf(
        _view(
          SessionStatus.invalidated,
          reason: SessionEndReason.staleGeneration,
        ),
      ),
      isA<LeaveStale>(),
    );
  });

  test('tones, stats, facts and Study this deck follow the kit', () {
    expect(SummaryOutcome.reviewFinished.tone, SummaryTone.success);
    expect(SummaryOutcome.leftEarly.tone, SummaryTone.paused);
    expect(SummaryOutcome.interrupted.tone, SummaryTone.paused);
    expect(SummaryOutcome.reset.tone, SummaryTone.ended);
    expect(SummaryOutcome.contentDeleted.tone, SummaryTone.ended);
    expect(SummaryOutcome.saveError.tone, SummaryTone.error);
    expect(
      [
        for (final outcome in SummaryOutcome.values)
          if (outcome.canStudyAgain) outcome,
      ],
      [
        SummaryOutcome.reviewFinished,
        SummaryOutcome.learningFinished,
        SummaryOutcome.leftEarly,
      ],
    );
    expect(SummaryOutcome.saveError.drawsStats, isFalse);
    expect(SummaryOutcome.interrupted.drawsStats, isTrue);
    expect(SummaryOutcome.schedulerChanged.drawsFacts, isFalse);
    expect(SummaryOutcome.saveError.drawsFacts, isTrue);
  });
}
