import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/providers/abandon_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/answer_study_turn_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/resume_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/reveal_recall_answer_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/save_recall_time_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/show_fill_hint_use_case_provider.dart';
import 'package:memox/features/study/presentation/states/study_turn_state.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/shared/support/held_run.dart';
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
  /// (BR-STUDY-004), and while a refused answer waits for [retry]: it stays
  /// the turn's answer. [cardId] names another card than [item]'s: a
  /// `match` answer on any pending pair of the board (BR-STUDY-049).
  Future<void> answer(
    StudyItem item,
    StudyAnswer answer, {
    bool shouldHoldFeedback = false,
    String? cardId,
  }) async {
    if (state.isLocked) return;
    await _answer(
      item,
      answer,
      shouldHoldFeedback: shouldHoldFeedback,
      cardId: cardId,
    );
  }

  Future<void> _answer(
    StudyItem item,
    StudyAnswer answer, {
    required bool shouldHoldFeedback,
    String? cardId,
  }) async {
    state = const StudyTurnState(isBusy: true);
    final pending = PendingAnswer(
      item,
      answer,
      shouldHoldFeedback: shouldHoldFeedback,
      cardId: cardId ?? item.cardId,
    );
    final outcome = await runHeld(
      () => ref.read(answerStudyTurnUseCaseProvider)(
        sessionId: sessionId,
        cardId: pending.cardId,
        answer: answer,
      ),
      // A bug takes the way out of any other failure: the stream shows
      // the session, nothing is held.
      onFailed: (failure) {
        if (ref.mounted) {
          state = failure is DatabaseLockedFailure
              ? StudyTurnState(unsaved: pending)
              : const StudyTurnState();
        }
      },
    );
    if (outcome == null || !ref.mounted) return;
    state = switch (outcome) {
      Ok(:final value) when shouldHoldFeedback => StudyTurnState(
        held: HeldTurn(item, value),
      ),
      // A refusal (the card moved on, the session closed) is the stream's to
      // show; nothing is held.
      _ => const StudyTurnState(),
    };
  }

  /// The answer a busy database refused, once more (E2).
  Future<void> retry() async {
    final pending = state.unsaved;
    if (pending == null || state.isBusy) return;
    await _answer(
      pending.item,
      pending.answer,
      shouldHoldFeedback: pending.shouldHoldFeedback,
      cardId: pending.cardId,
    );
  }

  /// `recall`: shows [item]'s meaning with [remainingMs] left; records no
  /// outcome (BR-STUDY-065, BR-STUDY-036). The stream shows it revealed. A
  /// refusal or a failure leaves the turn as it was, to be tapped again.
  /// Dropped while a write runs (BR-STUDY-004).
  Future<void> revealRecall(StudyItem item, int remainingMs) => _write(
    () => ref.read(revealRecallAnswerUseCaseProvider)(
      sessionId: sessionId,
      cardId: item.cardId,
      remainingMs: _turnTime(remainingMs),
    ),
  );

  /// `fill`: shows [item]'s hint; noted, it changes no result
  /// (BR-STUDY-028). As [revealRecall] on a refusal or a failure.
  Future<void> showFillHint(StudyItem item) => _write(
    () => ref.read(showFillHintUseCaseProvider)(
      sessionId: sessionId,
      cardId: item.cardId,
    ),
  );

  /// `recall`: keeps [item]'s time left, so the turn takes it up where it
  /// stopped (spec D12, BR-STUDY-036). A background save: it marks no write
  /// running, is skipped while one runs, and a failure is left to the next
  /// save or the turn's answer.
  Future<void> saveRecallTime(StudyItem item, int remainingMs) async {
    if (state.isBusy) return;
    try {
      await ref.read(saveRecallTimeUseCaseProvider)(
        sessionId: sessionId,
        cardId: item.cardId,
        remainingMs: _turnTime(remainingMs),
      );
    } on Failure {
      // Superseded by the next save or the answer.
    }
  }

  /// One write with no outcome to hold: busy while it runs, then back to
  /// idle whatever happened; the stream shows what changed.
  Future<void> _write(Future<Object?> Function() command) async {
    if (state.isBusy) return;
    state = const StudyTurnState(isBusy: true);
    await runHeld(
      command,
      // The turn stays as it was.
      onFailed: (_) {},
    );
    if (!ref.mounted) return;
    state = const StudyTurnState();
  }

  static int _turnTime(int remainingMs) => remainingMs.clamp(0, recallTurnMs);

  /// The held turn's mode met its continue condition (D5).
  void release() {
    if (state.held == null) return;
    state = const StudyTurnState();
  }

  /// ✕ and system Back: the session ends as `user_exit`; its turns stay
  /// (A3, BR-STUDY-014, BR-STUDY-019). The stream then shows the summary,
  /// so a held turn is dropped: it no longer has a session to continue.
  /// Returns false when the end could not be written; the session stays
  /// open and the screen says so (a refusal means it had already ended).
  Future<bool> abandon() async {
    try {
      await ref.read(abandonStudySessionUseCaseProvider)(sessionId: sessionId);
    } on Failure {
      return false;
    }
    if (ref.mounted) state = const StudyTurnState();
    return true;
  }

  /// A stalled round (its cards were deleted) moves on (spec D12). Not
  /// while a turn is held: it settles once released (D5).
  Future<void> settle() async {
    if (state.isBusy || state.held != null) return;
    state = const StudyTurnState(isBusy: true);
    await runHeld(
      () => ref.read(resumeStudySessionUseCaseProvider)(sessionId: sessionId),
      // The stream still shows the stalled session; the person can close it.
      onFailed: (_) {},
    );
    if (!ref.mounted) return;
    state = const StudyTurnState();
  }
}
