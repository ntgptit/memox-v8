import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// A built row of a round, with what preparing the round reads of it.
typedef RoundRowRecord = ({
  String cardId,
  int position,
  bool isPending,
  int? meaningSlot,
  int optionCount,
  String backFolded,
});

/// Row access for preparing a round (graded modes spec §8.2): its built rows,
/// the meaning source of its `guess` questions, the meaning slots of its
/// `match` boards and the stored options. It returns Drift rows and records,
/// never domain values, and runs inside the caller's transaction.
final class StudyRoundDao {
  StudyRoundDao(this._db);

  final AppDatabase _db;

  /// The built rows of [round] of [mode], in position order, with their
  /// card's `back_folded` and the options their question has stored.
  Future<List<RoundRowRecord>> builtRows(
    String sessionId,
    String mode,
    int round,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT q.card_id, q.position, q.status, q.meaning_slot,'
          ' c.back_folded, (SELECT COUNT(*) FROM study_guess_options o'
          '  WHERE o.session_id = q.session_id AND o.mode = q.mode'
          '  AND o.round = q.round AND o.card_id = q.card_id) AS option_count'
          ' FROM study_queue_items q JOIN card c ON c.id = q.card_id'
          ' AND c.delete_batch_id IS NULL'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
          ' AND q.position >= 0 ORDER BY q.position',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            Variable<int>(round),
          ],
          readsFrom: {_db.studyQueueItems, _db.card, _db.studyGuessOptions},
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('card_id'),
          position: row.read<int>('position'),
          isPending: row.read<String>('status') == 'pending',
          meaningSlot: row.read<int?>('meaning_slot'),
          optionCount: row.read<int>('option_count'),
          backFolded: row.read<String>('back_folded'),
        ),
    ];
  }

  /// The cards a `guess` question of [sessionId] can draw on: those of its
  /// queue and the learned, active cards of [rootId]'s tree, each with its
  /// `back_folded` (BR-STUDY-038; package 2a spec D5). Sorted, so a seeded
  /// draw repeats.
  Future<List<({String cardId, String meaningFolded})>> meaningSource(
    String sessionId,
    String rootId,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT c.id, c.back_folded AS meaning_folded FROM card c'
          ' JOIN deck d ON d.id = c.deck_id'
          ' JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE d.root_id = ? AND c.delete_batch_id IS NULL'
          ' AND d.delete_batch_id IS NULL'
          ' AND (cs.learned_at IS NOT NULL OR c.id IN'
          '  (SELECT card_id FROM study_queue_items WHERE session_id = ?))'
          ' ORDER BY c.back_folded, c.id',
          variables: [Variable<String>(rootId), Variable<String>(sessionId)],
          readsFrom: {
            _db.card,
            _db.deck,
            _db.cardSchedule,
            _db.studyQueueItems,
          },
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('id'),
          meaningFolded: row.read<String>('meaning_folded'),
        ),
    ];
  }

  /// Gives each card of [slots] its meaning slot in [round] of [mode].
  Future<void> setMeaningSlots(
    String sessionId,
    String mode,
    int round,
    Map<String, int> slots,
  ) async {
    for (final MapEntry(key: cardId, value: slot) in slots.entries) {
      await (_db.update(_db.studyQueueItems)..where(
            (q) =>
                q.sessionId.equals(sessionId) &
                q.mode.equals(mode) &
                q.round.equals(round) &
                q.cardId.equals(cardId),
          ))
          .write(StudyQueueItemsCompanion(meaningSlot: Value(slot)));
    }
  }

  /// Replaces the options of [cardId]'s question in [round] with
  /// [optionIds], in the order shown; with none when [optionIds] is null.
  Future<void> replaceOptions(
    String sessionId,
    int round,
    String cardId,
    List<String>? optionIds,
  ) async {
    await (_db.delete(_db.studyGuessOptions)..where(
          (o) =>
              o.sessionId.equals(sessionId) &
              o.round.equals(round) &
              o.cardId.equals(cardId),
        ))
        .go();
    if (optionIds == null) return;
    await _db.batch(
      (batch) => batch.insertAll(_db.studyGuessOptions, [
        for (final (slot, optionId) in optionIds.indexed)
          StudyGuessOptionsCompanion.insert(
            sessionId: sessionId,
            round: round,
            cardId: cardId,
            slot: slot,
            optionCardId: optionId,
          ),
      ]),
    );
  }
}
