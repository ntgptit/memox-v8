import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'srs_dao.g.dart';

/// Row access for `card_schedule` and `review_log`, plus the reads of `deck`
/// srs needs and the sessions a reset closes (`srs_queries.drift`). It
/// returns Drift rows, never domain values, and runs inside the caller's
/// transaction.
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/srs_queries.drift',
    'package:memox/core/database/queries/live_row_queries.drift',
  },
)
final class SrsDao extends DatabaseAccessor<AppDatabase> with _$SrsDaoMixin {
  SrsDao(super.attachedDatabase);

  /// The deck [id] names, unless it is in the Trash (spec §8).
  Future<Deck?> deckRow(String id) => liveDeckRow(id).getSingleOrNull();

  /// The root of [cardId]'s tree, reached through `card.deck_id` and then
  /// `deck.root_id` (BR-DECK-003); null when the card or its deck is in the
  /// Trash (BE-C3).
  Future<Deck?> rootOfCard(String cardId) =>
      rootOfLiveCard(cardId).getSingleOrNull();

  /// The deck [id] names with what a reset of its tree would clear, in one
  /// statement; null when it does not exist or is in the Trash. The counts
  /// leave the Trash out, as the deck list does (UC-DECK-003).
  Future<
    ({Deck deck, int cardCount, int learnedCardCount, int openSessionCount})?
  >
  resetSummaryRow(String id) async {
    final row = await resetSummaryOf(id).getSingleOrNull();
    if (row == null) return null;
    return (
      deck: row.d,
      cardCount: row.cardCount,
      learnedCardCount: row.learnedCardCount,
      openSessionCount: row.openSessionCount,
    );
  }

  Future<CardSchedule?> scheduleRow(String cardId) =>
      scheduleOfCard(cardId).getSingleOrNull();

  Future<void> insertSchedule(CardScheduleCompanion row) => createSchedule(row);

  Future<void> updateSchedule(String cardId, CardScheduleCompanion values) =>
      updateScheduleOf(values, cardId);

  Future<void> insertReviewLog(ReviewLogCompanion row) => createReviewLog(row);

  Future<void> updateDeck(String id, DeckCompanion values) =>
      updateLiveDeck(values, id);

  /// Gives every card of [rootId]'s tree, at any depth, a schedule row of
  /// [values]: the rows are deleted and created again (schema.md). Every
  /// column of [values] must be present.
  Future<void> replaceTreeSchedules(
    String rootId,
    CardScheduleCompanion values,
  ) async {
    await deleteTreeSchedules(rootId);
    await insertTreeSchedules(
      values.schedulerType.value,
      values.schedulerVersion.value,
      values.generation.value,
      values.learnedAt.value,
      values.dueAt.value,
      values.lastAnsweredAt.value,
      values.answerCount.value,
      values.lapseCount.value,
      values.currentBox.value,
      values.easeFactor.value,
      values.intervalDays.value,
      values.repetitions.value,
      rootId,
    );
  }

  /// Closes every `in_progress` session of [rootId]'s tree as `invalidated`
  /// with [endReason], in the transaction of the reset or the scheduler
  /// change (BR-STUDY-015, BR-STUDY-016).
  Future<void> invalidateOpenSessions(
    String rootId, {
    required String endReason,
    required DateTime now,
  }) => invalidateOpenSessionsOfTree(endReason, now, rootId);
}
