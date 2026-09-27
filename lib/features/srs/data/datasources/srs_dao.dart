import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

const _inProgress = 'in_progress';
const _invalidated = 'invalidated';

/// The sessions of the tree of [root]: opened on that root, or holding a card
/// that now lives in its tree. A deck moves between two trees mid-session
/// only when their scheduler and generation match (BR-SRS-006), and its cards
/// stay in the queue (IT-CONT-006); a reset or a scheduler change of the tree
/// they moved into must close that session too (BR-STUDY-015, BR-STUDY-016).
/// [session] names the `study_session` row the predicate reads.
String _ofTree(String session, String root) =>
    '($session.root_id = $root OR EXISTS (SELECT 1 FROM study_queue_items q'
    ' JOIN card c ON c.id = q.card_id JOIN deck k ON k.id = c.deck_id'
    ' WHERE q.session_id = $session.id AND k.root_id = $root'
    ' AND c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL))';

/// Row access for `card_schedule` and `review_log`, plus the reads of `deck`
/// srs needs and the sessions a reset closes. It returns Drift rows, never
/// domain values, and runs inside the caller's transaction.
final class SrsDao {
  SrsDao(this._db);

  final AppDatabase _db;

  /// The deck [id] names, unless it is in the Trash (spec §8).
  Future<Deck?> deckRow(String id) =>
      (_db.select(_db.deck)
            ..where((deck) => deck.id.equals(id) & deck.deleteBatchId.isNull()))
          .getSingleOrNull();

  /// The root of [cardId]'s tree, reached through `card.deck_id` and then
  /// `deck.root_id` — never `COALESCE(parent_id, id)` (BR-DECK-003); null
  /// when the card or its deck is in the Trash (BE-C3).
  Future<Deck?> rootOfCard(String cardId) async {
    final row = await _db
        .customSelect(
          'SELECT root.* FROM card c'
          ' JOIN deck d ON d.id = c.deck_id'
          ' JOIN deck root ON root.id = d.root_id'
          ' WHERE c.id = ? AND c.delete_batch_id IS NULL'
          ' AND d.delete_batch_id IS NULL AND root.delete_batch_id IS NULL',
          variables: [Variable<String>(cardId)],
          readsFrom: {_db.card, _db.deck},
        )
        .getSingleOrNull();
    return row == null ? null : _db.deck.map(row.data);
  }

  /// The deck [id] names with what a reset of its tree would clear, in one
  /// statement; null when it does not exist or is in the Trash. The counts
  /// leave the Trash out, as the deck list does (UC-DECK-003).
  Future<
    ({Deck deck, int cardCount, int learnedCardCount, int openSessionCount})?
  >
  resetSummaryRow(String id) async {
    final row = await _db
        .customSelect(
          'SELECT d.*,'
          ' (SELECT COUNT(*) FROM card c JOIN deck k ON k.id = c.deck_id'
          '  WHERE k.root_id = d.id AND c.delete_batch_id IS NULL'
          '  AND k.delete_batch_id IS NULL) AS card_count,'
          ' (SELECT COUNT(*) FROM card c JOIN deck k ON k.id = c.deck_id'
          '  JOIN card_schedule cs ON cs.card_id = c.id'
          '  WHERE k.root_id = d.id AND c.delete_batch_id IS NULL'
          '  AND k.delete_batch_id IS NULL AND cs.learned_at IS NOT NULL)'
          '  AS learned_card_count,'
          ' (SELECT COUNT(*) FROM study_session s'
          '  WHERE s.status = ? AND ${_ofTree('s', 'd.id')})'
          '  AS open_session_count'
          ' FROM deck d WHERE d.id = ? AND d.delete_batch_id IS NULL',
          variables: [
            const Variable<String>(_inProgress),
            Variable<String>(id),
          ],
          readsFrom: {
            _db.deck,
            _db.card,
            _db.cardSchedule,
            _db.studySession,
            _db.studyQueueItems,
          },
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      deck: _db.deck.map(row.data),
      cardCount: row.read<int>('card_count'),
      learnedCardCount: row.read<int>('learned_card_count'),
      openSessionCount: row.read<int>('open_session_count'),
    );
  }

  Future<CardSchedule?> scheduleRow(String cardId) => (_db.select(
    _db.cardSchedule,
  )..where((schedule) => schedule.cardId.equals(cardId))).getSingleOrNull();

  Future<void> insertSchedule(CardScheduleCompanion row) =>
      _db.into(_db.cardSchedule).insert(row);

  Future<void> updateSchedule(String cardId, CardScheduleCompanion values) =>
      (_db.update(
        _db.cardSchedule,
      )..where((schedule) => schedule.cardId.equals(cardId))).write(values);

  Future<void> insertReviewLog(ReviewLogCompanion row) =>
      _db.into(_db.reviewLog).insert(row);

  Future<void> updateDeck(String id, DeckCompanion values) =>
      (_db.update(_db.deck)..where((deck) => deck.id.equals(id))).write(values);

  /// Gives every card of [rootId]'s tree, at any depth, a schedule row of
  /// [values]: the rows are deleted and created again (schema.md). Every
  /// column of [values] must be present.
  Future<void> replaceTreeSchedules(
    String rootId,
    CardScheduleCompanion values,
  ) async {
    await _db.customUpdate(
      'DELETE FROM card_schedule WHERE card_id IN ('
      ' SELECT c.id FROM card c JOIN deck d ON d.id = c.deck_id WHERE d.root_id = ?)',
      variables: [Variable<String>(rootId)],
      updates: {_db.cardSchedule},
      updateKind: UpdateKind.delete,
    );
    await _db.customInsert(
      'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version,'
      ' generation, learned_at, due_at, last_answered_at, answer_count,'
      ' lapse_count, current_box, ease_factor, interval_days, repetitions)'
      ' SELECT c.id, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?'
      ' FROM card c JOIN deck d ON d.id = c.deck_id WHERE d.root_id = ?',
      variables: [
        Variable<String>(values.schedulerType.value),
        Variable<int>(values.schedulerVersion.value),
        Variable<int>(values.generation.value),
        Variable<DateTime>(values.learnedAt.value),
        Variable<DateTime>(values.dueAt.value),
        Variable<DateTime>(values.lastAnsweredAt.value),
        Variable<int>(values.answerCount.value),
        Variable<int>(values.lapseCount.value),
        Variable<int>(values.currentBox.value),
        Variable<double>(values.easeFactor.value),
        Variable<int>(values.intervalDays.value),
        Variable<int>(values.repetitions.value),
        Variable<String>(rootId),
      ],
      updates: {_db.cardSchedule},
    );
  }

  /// Closes every `in_progress` session of [rootId]'s tree as `invalidated`
  /// with [endReason], in the transaction of the reset or the scheduler
  /// change (BR-STUDY-015, BR-STUDY-016).
  Future<void> invalidateOpenSessions(
    String rootId, {
    required String endReason,
    required DateTime now,
  }) => _db.customUpdate(
    'UPDATE study_session SET status = ?, end_reason = ?, ended_at = ?'
    ' WHERE status = ? AND ${_ofTree('study_session', '?')}',
    variables: [
      const Variable<String>(_invalidated),
      Variable<String>(endReason),
      Variable<DateTime>(now),
      const Variable<String>(_inProgress),
      Variable<String>(rootId),
      Variable<String>(rootId),
    ],
    updates: {_db.studySession},
    updateKind: UpdateKind.update,
  );
}
