import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'study_queue_dao.g.dart';

/// `study_queue_items.status` of a row still to serve, and of a row done
/// (BR-STUDY-007).
const _pending = 'pending';
const _completed = 'completed';

/// Row access for `study_queue_items` (`study_queue_queries.drift`). It
/// returns Drift rows and card ids, never domain values, and runs inside the
/// caller's transaction.
@DriftAccessor(
  include: {'package:memox/core/database/queries/study_queue_queries.drift'},
)
final class StudyQueueDao extends DatabaseAccessor<AppDatabase>
    with _$StudyQueueDaoMixin {
  StudyQueueDao(super.attachedDatabase);

  /// Round 1 of [mode]: [cardIds] in serving order, each with its entry of
  /// [directions] when there are directions (BR-MODE-015). One insert per
  /// card, inside the caller's transaction (ADR-020 D9).
  Future<void> insertFirstRound(
    String sessionId,
    String mode,
    List<String> cardIds, {
    List<String>? directions,
  }) async {
    for (final (position, cardId) in cardIds.indexed) {
      await createQueueItem(
        StudyQueueItemsCompanion.insert(
          sessionId: sessionId,
          mode: mode,
          cardId: cardId,
          position: position,
          status: _pending,
          direction: Value(directions?[position]),
        ),
      );
    }
  }

  /// The row [sessionId] serves next in [mode] at [cursor] (schema.md,
  /// "cursor + available_at"; BR-STUDY-005): in the lowest round with a
  /// pending row, the first by position among the rows due at the cursor,
  /// else the one due soonest. Null when the mode has no pending row, or when
  /// that round is not built yet.
  Future<StudyQueueItem?> headRow(String sessionId, String mode, int cursor) =>
      queueHeadRow(sessionId, mode, cursor).getSingleOrNull();

  /// [cardId]'s pending row in the lowest pending round of [mode], once that
  /// round is built: a `match` board serves any of its rows, and the caller
  /// checks the row is on the current board.
  Future<StudyQueueItem?> boardRow(
    String sessionId,
    String mode,
    String cardId,
  ) => queueBoardRow(sessionId, mode, cardId).getSingleOrNull();

  /// The row is done, after [answers] turns (BR-STUDY-007).
  Future<void> leave(StudyQueueItem row, {required int answers}) => _update(
    row,
    StudyQueueItemsCompanion(
      status: const Value(_completed),
      answersInSession: Value(answers),
    ),
  );

  /// The row stays pending after [answers] turns, served again from the
  /// cursor [availableAt] when one is given (BR-STUDY-005).
  Future<void> keep(
    StudyQueueItem row, {
    required int answers,
    int? availableAt,
  }) => _update(
    row,
    StudyQueueItemsCompanion(
      answersInSession: Value(answers),
      availableAt: availableAt == null
          ? const Value.absent()
          : Value(availableAt),
    ),
  );

  /// `recall`: the answer of [row]'s turn is shown, and its time stops at
  /// [remainingMs] (BR-STUDY-065, BR-STUDY-036).
  Future<void> reveal(StudyQueueItem row, {required int remainingMs}) =>
      _update(
        row,
        StudyQueueItemsCompanion(
          isRevealed: const Value(1),
          remainingMs: Value(remainingMs),
        ),
      );

  /// `recall`: the time left of [row]'s turn (BR-STUDY-036).
  Future<void> saveTimeLeft(StudyQueueItem row, {required int remainingMs}) =>
      _update(row, StudyQueueItemsCompanion(remainingMs: Value(remainingMs)));

  /// `fill`: the hint of [row]'s turn is shown (BR-STUDY-028).
  Future<void> showHint(StudyQueueItem row) =>
      _update(row, const StudyQueueItemsCompanion(hintShown: Value(1)));

  /// `guess`: the options stored for [row], in the order shown
  /// (BR-STUDY-041).
  Future<List<String>> optionIds(StudyQueueItem row) =>
      guessOptionIdsOf(row.sessionId, row.mode, row.round, row.cardId).get();

  /// `match`: the pending pairs of [row]'s round between the positions
  /// [from] and [to], card id to `back_folded` (graded modes spec §7.6).
  Future<Map<String, String>> pendingMeanings(
    StudyQueueItem row, {
    required int from,
    required int to,
  }) async => {
    for (final pair in await pendingMeaningsOf(
      row.sessionId,
      row.mode,
      row.round,
      from,
      to,
    ).get())
      pair.cardId: pair.backFolded,
  };

  /// `match`: [row] and [otherCardId]'s row of the same round swap their
  /// meaning slots (graded modes spec §7.6).
  Future<void> swapMeaningSlots(StudyQueueItem row, String otherCardId) async {
    final other = await queueItemOf(
      row.sessionId,
      row.mode,
      row.round,
      otherCardId,
    ).getSingle();
    await _update(
      row,
      StudyQueueItemsCompanion(meaningSlot: Value(other.meaningSlot)),
    );
    await _update(
      other,
      StudyQueueItemsCompanion(meaningSlot: Value(row.meaningSlot)),
    );
  }

  /// Enrolls [cardId] in [round] of [mode] once: a second enrollment changes
  /// nothing (BR-STUDY-060, BR-STUDY-062).
  Future<void> enroll(
    String sessionId,
    String mode,
    int round,
    String cardId,
  ) => enrollQueueItem(sessionId, mode, round, cardId);

  /// Whether [cardId] still has a row to serve in any mode of [sessionId].
  Future<bool> hasPendingRows(String sessionId, String cardId) =>
      queueHasPendingRowsOf(sessionId, cardId).getSingle();

  /// The lowest round of [mode] with a pending row; null when the stage has
  /// none left.
  Future<int?> lowestPendingRound(String sessionId, String mode) =>
      lowestPendingRoundOf(sessionId, mode).getSingle();

  /// Whether [round] of [mode] still waits to be built (spec D7).
  Future<bool> isUnbuilt(String sessionId, String mode, int round) =>
      roundIsUnbuilt(sessionId, mode, round).getSingle();

  /// The cards of [round] of [mode], in serving order; a round not built yet
  /// lists them by id, so a seeded shuffle of it repeats.
  Future<List<String>> cardsOf(String sessionId, String mode, int round) =>
      roundCardIds(sessionId, mode, round).get();

  /// Builds [round] of [mode]: [order] numbers its rows from 0, and the
  /// positions do not change after this (schema.md).
  Future<void> build(
    String sessionId,
    String mode,
    int round,
    List<String> order,
  ) async {
    for (final (position, cardId) in order.indexed) {
      await updateQueueItem(
        StudyQueueItemsCompanion(position: Value(position)),
        sessionId,
        mode,
        round,
        cardId,
      );
    }
  }

  Future<void> _update(StudyQueueItem row, StudyQueueItemsCompanion values) =>
      updateQueueItem(values, row.sessionId, row.mode, row.round, row.cardId);
}
