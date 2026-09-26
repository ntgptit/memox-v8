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

  /// Answers [item]. [shouldHoldFeedback] keeps it on screen with its result
  /// until [release] (D5). A busy database keeps the answer for [retry]
  /// (E2); any other failure has already failed the session, whose summary
  /// the stream shows (E3, spec D6). Dropped while a write runs
  /// (BR-STUDY-004). [cardId] names another card than [item]'s: a `match`
  /// answer on any pending pair of the board (BR-STUDY-049).
  Future<void> answer(
    StudyItem item,
    StudyAnswer answer, {
    bool shouldHoldFeedback = false,
    String? cardId,
  }) async {
    if (state.isBusy) return;
    state = const StudyTurnState(isBusy: true);
    final pending = PendingAnswer(
      item,
      answer,
      shouldHoldFeedback: shouldHoldFeedback,
      cardId: cardId ?? item.cardId,
    );
    try {
      final outcome = await ref.read(answerStudyTurnUseCaseProvider)(
        sessionId: sessionId,
        cardId: pending.cardId,
        answer: answer,
      );
      if (!ref.mounted) return;
      state = switch (outcome) {
        Ok(:final value) when shouldHoldFeedback => StudyTurnState(
          held: HeldTurn(item, value),
        ),
        // A refusal (the card moved on, the session closed) is the stream's
        // to show; nothing is held.
        _ => const StudyTurnState(),
      };
    } on DatabaseLockedFailure {
      if (!ref.mounted) return;
      state = StudyTurnState(unsaved: pending);
    } on Failure {
      if (!ref.mounted) return;
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
      shouldHoldFeedback: pending.shouldHoldFeedback,
      cardId: pending.cardId,
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

  /// A stalled round (its cards were deleted) moves on (spec D12). Not
  /// while a turn is held: it settles once released (D5).
  Future<void> settle() async {
    if (state.isBusy || state.held != null) return;
    state = const StudyTurnState(isBusy: true);
    try {
      await ref.read(resumeStudySessionUseCaseProvider)(sessionId: sessionId);
    } on Failure {
      // The stream still shows the stalled session; the person can close it.
    }
    if (!ref.mounted) return;
    state = const StudyTurnState();
  }
}
