import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/providers/open_learning_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/open_review_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/resume_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/states/study_start_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_entry_controller.g.dart';

/// The Study Entry's starts (UC-STUDY-001 steps 3–5, A3b; UC-STUDY-003):
/// Learn, Review and Continue. One runs at a time (BR-STUDY-004); a refusal
/// and a failed write each leave their state for the screen, and Try again
/// repeats the last start. It answers the session to open; navigating is
/// the screen's.
@riverpod
class StudyEntryController extends _$StudyEntryController {
  /// A refusal that means the cards or the session changed meanwhile; any
  /// other refusal is a start the screen should not have made, and shows as
  /// a failed start (nothing was written either way).
  static const Set<StudyRejection> _changedMeanwhile = {
    StudyRejection.nothingToLearn,
    StudyRejection.nothingDue,
    StudyRejection.modeUnavailable,
    StudyRejection.notFound,
    StudyRejection.sessionClosed,
    StudyRejection.sessionExpired,
    StudyRejection.staleGeneration,
  };

  @override
  StudyStartState build(String deckId) => const StudyStartState();

  /// Runs [start]; answers the session to open, or null when it was dropped,
  /// refused or failed.
  Future<String?> start(StudyStart start) async {
    if (state.isStarting) return null;
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
