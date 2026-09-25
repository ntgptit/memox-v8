import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study_mode/domain/models/match_mode.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// Writes one answered turn inside the caller's transaction (spec §7.3
/// steps 2–7; graded modes spec §8.1): the row the session serves, what the
/// mode judges it by, the review the srs records, what the answer does to
/// the row, and a card's end of learning. Moving the session on stays with
/// the repository.
final class StudyTurnDataSource {
  StudyTurnDataSource(AppDatabase db, this._schedules, this._cards)
    : _dao = StudySessionDao(db),
      _queue = StudyQueueDao(db);

  final ScheduleRepository _schedules;
  final CardRepository _cards;
  final StudySessionDao _dao;
  final StudyQueueDao _queue;

  /// [answer] on [cardId] in an open [session] of a [type] root (spec §7.3
  /// steps 2–7; graded modes spec §8.1). The caller moves the session on
  /// after an answered turn (step 8).
  Future<Outcome<TurnResult, StudyRejection>> answer(
    StudySession session,
    SchedulerType type,
    String cardId,
    StudyAnswer answer,
    DateTime at,
  ) async {
    final mode = StudyMode.fromCode(session.currentMode);
    final row = await _servedRow(session, mode, cardId);
    if (row == null) return const Rejected(StudyRejection.notCurrentCard);

    final scheduler = schedulerFor(type);
    final TurnVerdict verdict;
    switch (mode.handler.judge(
      answer,
      await _contextOf(mode, row),
      scheduler,
    )) {
      case Rejected(:final reason):
        return Rejected(StudyRejection.ofModeRefusal(reason));
      case Ok(:final value):
        verdict = value;
    }
    final action = verdict.action;
    final kind = SessionKind.values.byName(session.sessionKind);
    if (action != null) {
      final recorded = await _schedules.recordTurn(
        ReviewTurn(
          cardId: cardId,
          sessionId: session.id,
          generation: session.generation,
          kind: turnKindOf(
            kind,
            round: row.round,
            answersInSession: row.answersInSession,
          ),
          modeCode: mode.code,
          action: action,
          directionCode: row.direction,
          answeredAt: at,
          outcomeReasonCode: verdict.outcomeReason?.code,
          comparisonVersion: verdict.comparisonVersion,
          usedHint: verdict.usedHint,
        ),
      );
      if (recorded case Rejected(:final reason)) {
        return Rejected(StudyRejection.ofTurnRefusal(reason));
      }
    }

    final cursor = session.cursor + 1;
    final step = mode.handler.stepAfter(
      lapsed: action != null && scheduler.isLapse(action),
      answersInSession: row.answersInSession,
    );
    await _apply(
      step,
      row,
      answers: row.answersInSession + (action == null ? 0 : 1),
      cursor: cursor,
      at: at,
    );
    if (verdict.takesMeaningSlotOf case final other?) {
      await _queue.swapMeaningSlots(row, other);
    }
    await _dao.setCursor(session.id, cursor);
    // A card finishes learning with the last stage it takes part in; a
    // card at the cap stays new (BR-STUDY-053, UC-STUDY-001 A2b).
    if (kind == SessionKind.learning &&
        step is! LeaveAtCap &&
        !await _queue.hasPendingRows(session.id, cardId)) {
      await _required(
        _schedules.completeLearning(
          cardId: cardId,
          generation: session.generation,
          now: at,
        ),
        'finishing learning $cardId',
      );
    }
    return Ok(TurnResult(isCorrect: verdict.isCorrect));
  }

  /// [cardId]'s row that [session] serves in [mode]: the head row, or in a
  /// mode that does not serve in order, the card's pending pair on the board
  /// of the head row (graded modes spec §7.6). Null when the card is not
  /// served.
  Future<StudyQueueItem?> _servedRow(
    StudySession session,
    StudyMode mode,
    String cardId,
  ) async {
    final head = await _queue.headRow(session.id, mode.code, session.cursor);
    if (head == null || mode.handler.servesInOrder) {
      return head?.cardId == cardId ? head : null;
    }
    final row = await _queue.boardRow(session.id, mode.code, cardId);
    if (row == null) return null;
    return matchBoardOf(row.position) == matchBoardOf(head.position)
        ? row
        : null;
  }

  /// What [mode] judges the turn on [row] by: the card's folded fields, the
  /// row's flags, and the stored options or the pending pairs of the board
  /// (graded modes spec §7.2, §8.1 step 3).
  Future<TurnContext> _contextOf(StudyMode mode, StudyQueueItem row) async {
    final card = await _dao.cardRow(row.cardId);
    final board = matchBoardOf(row.position) * matchBoardSize;
    return TurnContext(
      card: TurnCard(
        cardId: card.id,
        frontFolded: card.frontFolded,
        backFolded: card.backFolded,
      ),
      isRevealed: row.isRevealed == 1,
      isHintShown: row.hintShown == 1,
      guessOptionIds: mode.handler.asksWithOptions
          ? await _queue.optionIds(row)
          : null,
      boardMeanings: mode.handler.servesInOrder
          ? const {}
          : await _queue.pendingMeanings(
              row,
              from: board,
              to: board + matchBoardSize - 1,
            ),
    );
  }

  /// What [step] does to [row] (spec §5.5).
  Future<void> _apply(
    RowStep step,
    StudyQueueItem row, {
    required int answers,
    required int cursor,
    required DateTime at,
  }) async {
    switch (step) {
      case Leave():
        await _queue.leave(row, answers: answers);
      case ComeBack(:final afterTurns):
        await _queue.keep(
          row,
          answers: answers,
          availableAt: cursor + afterTurns,
        );
      case LeaveAtCap():
        await _queue.leave(row, answers: answers);
        // Nothing turns the flag off (BR-STUDY-073, BR-CARD-009).
        await _required(
          _cards.setFlagged(cardIds: {row.cardId}, isFlagged: true, now: at),
          'flagging ${row.cardId}',
        );
      case StayAndEnroll():
        await _queue.keep(row, answers: answers);
        await _queue.enroll(row.sessionId, row.mode, row.round + 1, row.cardId);
      case LeaveAndEnroll():
        await _queue.leave(row, answers: answers);
        await _queue.enroll(row.sessionId, row.mode, row.round + 1, row.cardId);
    }
  }
}

/// A write the turn cannot go without. A refusal there means study and the
/// feature it calls disagree: a bug, which rolls the turn back (spec §7.3,
/// E3).
Future<void> _required<R extends Enum>(
  Future<Outcome<void, R>> write,
  String what,
) async {
  if (await write case Rejected(:final reason)) {
    throw StateError('$what refused: $reason');
  }
}
