import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/providers/abandon_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/answer_study_turn_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/resume_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/states/study_turn_state.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_controller.g.dart';

/// The one write path of a session (spec D4): its answers, its end, and the
/// settling of a stalled round. The session's stream shows what happened;
/// this holds only what the stream cannot: a write running, a turn held on
/// screen (D5), an answer a busy database refused (E2).
@riverpod
class StudySessionController extends _$StudySessionController {
  @override
  StudyTurnState build(String sessionId) => const StudyTurnState();

  /// Answers [item]. [holdsFeedback] keeps it on screen with its result
  /// until [release] (D5). A busy database keeps the answer for [retry]
  /// (E2); any other failure has already failed the session, whose summary
  /// the stream shows (E3, spec D6). Dropped while a write runs
  /// (BR-STUDY-004).
  Future<void> answer(
    StudyItem item,
    StudyAnswer answer, {
    bool holdsFeedback = false,
  }) async {
    if (state.isBusy) return;
    state = const StudyTurnState(isBusy: true);
    final pending = PendingAnswer(item, answer, holdsFeedback: holdsFeedback);
    try {
      final outcome = await ref.read(answerStudyTurnUseCaseProvider)(
        sessionId: sessionId,
        cardId: item.cardId,
        answer: answer,
      );
      state = switch (outcome) {
        Ok(:final value) when holdsFeedback => StudyTurnState(
          held: HeldTurn(item, value),
        ),
        // A refusal (the card moved on, the session closed) is the stream's
        // to show; nothing is held.
        _ => const StudyTurnState(),
      };
    } on DatabaseLockedFailure {
      state = StudyTurnState(unsaved: pending);
    } on Failure {
      state = const StudyTurnState();
    }
  }

  /// The answer a busy database refused, once more (E2).
  Future<void> retry() async {
    final pending = state.unsaved;
    if (pending == null) return;
    await answer(
      pending.item,
      pending.answer,
      holdsFeedback: pending.holdsFeedback,
    );
  }

  /// The held turn's mode met its continue condition (D5).
  void release() {
    if (state.held == null) return;
    state = const StudyTurnState();
  }

  /// ✕ and system Back: the session ends as `user_exit`; its turns stay
  /// (A3, BR-STUDY-014, BR-STUDY-019). The stream then shows the summary.
  Future<void> abandon() async {
    try {
      await ref.read(abandonStudySessionUseCaseProvider)(sessionId: sessionId);
    } on Failure {
      // The session stays open; the next start closes it (BR-STUDY-072).
    }
  }

  /// A stalled round (its cards were deleted) moves on (spec D12).
  Future<void> settle() async {
    if (state.isBusy) return;
    state = const StudyTurnState(isBusy: true);
    try {
      await ref.read(resumeStudySessionUseCaseProvider)(sessionId: sessionId);
    } on Failure {
      // The stream still shows the stalled session; the person can close it.
    } finally {
      state = const StudyTurnState();
    }
  }
}
