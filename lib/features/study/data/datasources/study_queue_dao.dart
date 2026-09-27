import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// `study_queue_items.status` of a row still to serve, and of a row done
/// (BR-STUDY-007).
const _pending = 'pending';
const _completed = 'completed';

/// The position of a row enrolled in a round not built yet: the round is
/// shuffled and numbered when the round before it ends (spec D7).
const _unbuilt = -1;

/// Row access for `study_queue_items`. It returns Drift rows and card ids,
/// never domain values, and runs inside the caller's transaction.
final class StudyQueueDao {
  StudyQueueDao(this._db);

  final AppDatabase _db;

  /// Round 1 of [mode]: [cardIds] in serving order, each with its entry of
  /// [directions] when there are directions (BR-MODE-015).
  Future<void> insertFirstRound(
    String sessionId,
    String mode,
    List<String> cardIds, {
    List<String>? directions,
  }) => _db.batch(
    (batch) => batch.insertAll(_db.studyQueueItems, [
      for (final (position, cardId) in cardIds.indexed)
        StudyQueueItemsCompanion.insert(
          sessionId: sessionId,
          mode: mode,
          cardId: cardId,
          position: position,
          status: _pending,
          direction: Value(directions?[position]),
        ),
    ]),
  );

  /// The row [sessionId] serves next in [mode] at [cursor] (schema.md,
  /// "cursor + available_at"; BR-STUDY-005): in the lowest round with a
  /// pending row, the first by position among the rows due at the cursor,
  /// else the one due soonest. Null when the mode has no pending row, or when
  /// that round is not built yet.
  Future<StudyQueueItem?> headRow(
    String sessionId,
    String mode,
    int cursor,
  ) async {
    final row = await _db
        .customSelect(
          'SELECT q.* FROM study_queue_items q'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.status = ?'
          ' AND q.position >= 0 AND q.round = ($_lowestPendingRound)'
          ' ORDER BY q.available_at > ?,'
          ' CASE WHEN q.available_at > ? THEN q.available_at ELSE 0 END,'
          ' q.position LIMIT 1',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            const Variable<String>(_pending),
            const Variable<String>(_pending),
            Variable<int>(cursor),
            Variable<int>(cursor),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingleOrNull();
    return row == null ? null : _db.studyQueueItems.map(row.data);
  }

  /// [cardId]'s pending row in the lowest pending round of [mode], once that
  /// round is built: a `match` board serves any of its rows, and the caller
  /// checks the row is on the current board.
  Future<StudyQueueItem?> boardRow(
    String sessionId,
    String mode,
    String cardId,
  ) async {
    final row = await _db
        .customSelect(
          'SELECT q.* FROM study_queue_items q'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.status = ?'
          ' AND q.card_id = ? AND q.position >= 0'
          ' AND q.round = ($_lowestPendingRound)',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            const Variable<String>(_pending),
            Variable<String>(cardId),
            const Variable<String>(_pending),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingleOrNull();
    return row == null ? null : _db.studyQueueItems.map(row.data);
  }

  /// The lowest round of `q`'s mode with a pending row.
  static const _lowestPendingRound =
      'SELECT MIN(p.round) FROM study_queue_items p'
      ' WHERE p.session_id = q.session_id AND p.mode = q.mode AND p.status = ?';

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
  Future<List<String>> optionIds(StudyQueueItem row) async {
    final options =
        await (_db.select(_db.studyGuessOptions)
              ..where(
                (o) =>
                    o.sessionId.equals(row.sessionId) &
                    o.mode.equals(row.mode) &
                    o.round.equals(row.round) &
                    o.cardId.equals(row.cardId),
              )
              ..orderBy([(o) => OrderingTerm(expression: o.slot)]))
            .get();
    return [for (final option in options) option.optionCardId];
  }

  /// `match`: the pending pairs of [row]'s round between the positions
  /// [from] and [to], card id to `back_folded` (graded modes spec §7.6).
  Future<Map<String, String>> pendingMeanings(
    StudyQueueItem row, {
    required int from,
    required int to,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT q.card_id, c.back_folded FROM study_queue_items q'
          ' JOIN card c ON c.id = q.card_id AND c.delete_batch_id IS NULL'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
          ' AND q.status = ? AND q.position BETWEEN ? AND ?',
          variables: [
            Variable<String>(row.sessionId),
            Variable<String>(row.mode),
            Variable<int>(row.round),
            const Variable<String>(_pending),
            Variable<int>(from),
            Variable<int>(to),
          ],
          readsFrom: {_db.studyQueueItems, _db.card},
        )
        .get();
    return {
      for (final pair in rows)
        pair.read<String>('card_id'): pair.read<String>('back_folded'),
    };
  }

  /// `match`: [row] and [otherCardId]'s row of the same round swap their
  /// meaning slots (graded modes spec §7.6).
  Future<void> swapMeaningSlots(StudyQueueItem row, String otherCardId) async {
    final other =
        await (_db.select(_db.studyQueueItems)..where(
              (q) =>
                  q.sessionId.equals(row.sessionId) &
                  q.mode.equals(row.mode) &
                  q.round.equals(row.round) &
                  q.cardId.equals(otherCardId),
            ))
            .getSingle();
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
  ) => _db
      .into(_db.studyQueueItems)
      .insert(
        StudyQueueItemsCompanion.insert(
          sessionId: sessionId,
          mode: mode,
          round: Value(round),
          cardId: cardId,
          position: _unbuilt,
          status: _pending,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Whether [cardId] still has a row to serve in any mode of [sessionId].
  Future<bool> hasPendingRows(String sessionId, String cardId) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM study_queue_items WHERE session_id = ?'
          ' AND card_id = ? AND status = ?) AS pending',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(cardId),
            const Variable<String>(_pending),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingle();
    return row.read<bool>('pending');
  }

  /// The lowest round of [mode] with a pending row; null when the stage has
  /// none left.
  Future<int?> lowestPendingRound(String sessionId, String mode) async {
    final row = await _db
        .customSelect(
          'SELECT MIN(round) AS round FROM study_queue_items'
          ' WHERE session_id = ? AND mode = ? AND status = ?',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            const Variable<String>(_pending),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingle();
    return row.read<int?>('round');
  }

  /// Whether [round] of [mode] still waits to be built (spec D7).
  Future<bool> isUnbuilt(String sessionId, String mode, int round) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM study_queue_items WHERE session_id = ?'
          ' AND mode = ? AND round = ? AND position < 0) AS unbuilt',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            Variable<int>(round),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingle();
    return row.read<bool>('unbuilt');
  }

  /// The cards of [round] of [mode], in serving order; a round not built yet
  /// lists them by id, so a seeded shuffle of it repeats.
  Future<List<String>> cardsOf(String sessionId, String mode, int round) async {
    final rows =
        await (_db.select(_db.studyQueueItems)
              ..where(
                (q) =>
                    q.sessionId.equals(sessionId) &
                    q.mode.equals(mode) &
                    q.round.equals(round),
              )
              ..orderBy([
                (q) => OrderingTerm(expression: q.position),
                (q) => OrderingTerm(expression: q.cardId),
              ]))
            .get();
    return [for (final row in rows) row.cardId];
  }

  /// Builds [round] of [mode]: [order] numbers its rows from 0, and the
  /// positions do not change after this (schema.md).
  Future<void> build(
    String sessionId,
    String mode,
    int round,
    List<String> order,
  ) async {
    for (final (position, cardId) in order.indexed) {
      await (_db.update(_db.studyQueueItems)..where(
            (q) =>
                q.sessionId.equals(sessionId) &
                q.mode.equals(mode) &
                q.round.equals(round) &
                q.cardId.equals(cardId),
          ))
          .write(StudyQueueItemsCompanion(position: Value(position)));
    }
  }

  Future<void> _update(StudyQueueItem row, StudyQueueItemsCompanion values) =>
      (_db.update(_db.studyQueueItems)..where(
            (q) =>
                q.sessionId.equals(row.sessionId) &
                q.mode.equals(row.mode) &
                q.round.equals(row.round) &
                q.cardId.equals(row.cardId),
          ))
          .write(values);
}
