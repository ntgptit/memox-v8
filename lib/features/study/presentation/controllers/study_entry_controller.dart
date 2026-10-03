import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/providers/find_other_deck_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/open_learning_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/open_review_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/resume_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/states/study_start_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_entry_controller.g.dart';

/// The Study Entry's starts (UC-STUDY-001 steps 3–5, A3b; UC-STUDY-003):
/// Learn, Review and Continue. One runs at a time (BR-STUDY-004); a refusal
/// and a failed write each leave their state for the screen, and Try again
/// repeats the last start. A Learn or a Review asks first when another
/// deck's session is open (R3). It answers the session to open; navigating
/// is the screen's.
@riverpod
class StudyEntryController extends _$StudyEntryController {
  /// A refusal that means the cards or the session changed meanwhile; any
  /// other refusal is a start the screen should not have made, and shows as
  /// a failed start (nothing was written either way).
  static const Set<StudyRejection> _changedMeanwhile = {
    StudyRejection.nothingToLearn,
    StudyRejection.nothingDue,
    StudyRejection.modeUnavailable,
    // The root's scheduler changed while the direction sheet was open:
    // self-assess is no longer offered (UC-STUDY-003 E1).
    StudyRejection.modeNotOffered,
    StudyRejection.notFound,
    StudyRejection.sessionClosed,
    StudyRejection.sessionExpired,
    StudyRejection.staleGeneration,
  };

  /// The check of another deck's session is running: a second start waits
  /// (BR-STUDY-004) so two dialogs never stack.
  bool _isConfirming = false;

  @override
  StudyStartState build(String deckId) => const StudyStartState();

  /// Runs [start]; answers the session to open, or null when it was dropped,
  /// refused, failed or not confirmed. A Learn or a Review ends the open
  /// session of another deck (BR-STUDY-072); with [confirmEnd] given it asks
  /// first, with that deck's name, and starts nothing on false (R3). Continue
  /// and Try again never ask.
  Future<String?> start(
    StudyStart start, {
    Future<bool> Function(String deckName)? confirmEnd,
  }) async {
    if (state.isStarting || _isConfirming) return null;
    if (confirmEnd != null &&
        start is! ContinueStart &&
        !await _isEndConfirmed(confirmEnd)) {
      return null;
    }
    if (!ref.mounted) return null;
    state = StudyStartState(
      status: StudyStartStatus.starting,
      lastStart: start,
    );
    try {
      final outcome = await _run(start);
      if (!ref.mounted) return null;
      switch (outcome) {
        case Ok(:final value):
          state = const StudyStartState();
          return value;
        case Rejected(:final reason):
          state = _changedMeanwhile.contains(reason)
              ? StudyStartState(
                  status: StudyStartStatus.refused,
                  refusal: reason,
                  lastStart: start,
                )
              : StudyStartState(
                  status: StudyStartStatus.failed,
                  lastStart: start,
                );
          return null;
      }
    } on Failure {
      if (!ref.mounted) return null;
      state = StudyStartState(
        status: StudyStartStatus.failed,
        lastStart: start,
      );
      return null;
    }
  }

  /// Try again: the last start, as it was asked.
  Future<String?> retry() async {
    final last = state.lastStart;
    if (last == null) return null;
    return start(last);
  }

  /// A new pick drops a refusal or a failure the last start left, so Try
  /// again and the banner do not outlive the mode they were about (2.02). A
  /// start that runs is left alone (BR-STUDY-004).
  void dismissFailure() {
    if (state.status == StudyStartStatus.idle || state.isStarting) return;
    state = const StudyStartState();
  }

  /// True when no other deck's session would end, or the person confirmed it.
  Future<bool> _isEndConfirmed(
    Future<bool> Function(String deckName) confirmEnd,
  ) async {
    _isConfirming = true;
    try {
      final other = await ref.read(findOtherDeckSessionUseCaseProvider)(
        deckId: deckId,
      );
      return other == null || await confirmEnd(other);
    } on Failure {
      // The read failed: the start itself meets the same store and reports a
      // failed write, so it is not held back here.
      return true;
    } finally {
      _isConfirming = false;
    }
  }

  Future<Outcome<String, StudyRejection>> _run(StudyStart start) =>
      switch (start) {
        LearnStart() => ref.read(openLearningSessionUseCaseProvider)(
          deckId: deckId,
        ),
        ReviewStart(:final mode, :final direction) => ref.read(
          openReviewSessionUseCaseProvider,
        )(deckId: deckId, mode: mode, direction: direction),
        ContinueStart(:final sessionId) => _continue(sessionId),
      };

  Future<Outcome<String, StudyRejection>> _continue(String sessionId) async =>
      switch (await ref.read(resumeStudySessionUseCaseProvider)(
        sessionId: sessionId,
      )) {
        Ok() => Ok(sessionId),
        Rejected(:final reason) => Rejected(reason),
      };
}
