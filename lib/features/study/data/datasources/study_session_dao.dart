import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';

/// A card a session can take, as the data conditions read it.
typedef StudyCardRow = ({String cardId, bool hasExample});

/// Row access for `study_session`, plus the reads of `deck`, `card` and
/// `card_schedule` a session is built from. It returns Drift rows and
/// records, never domain values, and runs inside the caller's transaction.
final class StudySessionDao {
  StudySessionDao(this._db);

  final AppDatabase _db;

  /// The deck [id] names, unless it is in the Trash.
  Future<Deck?> deckRow(String id) =>
      (_db.select(_db.deck)
            ..where((deck) => deck.id.equals(id) & deck.deleteBatchId.isNull()))
          .getSingleOrNull();

  /// The active cards of [deckId] and its whole subtree that are not learned
  /// yet, oldest first (BR-STUDY-051, BR-STUDY-057).
  Future<List<StudyCardRow>> newCards(String deckId) => _subtreeCards(
    deckId,
    where: 'cs.learned_at IS NULL',
    orderBy: 'c.created_at, c.id',
  );

  /// The active learned cards of [deckId] and its whole subtree that are due
  /// at [now], earliest due first (BR-STUDY-001, BR-STUDY-002, BR-STUDY-051).
  Future<List<StudyCardRow>> dueCards(String deckId, DateTime now) =>
      _subtreeCards(
        deckId,
        where: 'cs.learned_at IS NOT NULL AND cs.due_at <= ?',
        orderBy: 'cs.due_at, c.created_at, c.id',
        variables: [Variable<DateTime>(now)],
      );

  /// The active cards of [deckId]'s subtree matching [where], in [orderBy]
  /// order. The subtree is walked through `parent_id` (schema.md "Duyệt cây").
  Future<List<StudyCardRow>> _subtreeCards(
    String deckId, {
    required String where,
    required String orderBy,
    List<Variable<Object>> variables = const [],
  }) async {
    final rows = await _db
        .customSelect(
          'WITH RECURSIVE subtree(id) AS ('
          ' SELECT id FROM deck WHERE id = ? AND delete_batch_id IS NULL'
          ' UNION SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id'
          ' WHERE d.delete_batch_id IS NULL)'
          ' SELECT c.id, c.example IS NOT NULL AS has_example FROM card c'
          ' JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE c.deck_id IN (SELECT id FROM subtree)'
          ' AND c.delete_batch_id IS NULL AND $where'
          ' ORDER BY $orderBy',
          variables: [Variable<String>(deckId), ...variables],
          readsFrom: {_db.deck, _db.card, _db.cardSchedule},
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('id'),
          hasExample: row.read<bool>('has_example'),
        ),
    ];
  }

  /// The distinct meanings (`back_folded`) of [sessionCardIds] and of the
  /// learned, active cards of [rootId]'s tree: the distractor source of
  /// `guess` (BR-STUDY-038; spec D5).
  Future<int> distinctMeaningCount(
    String rootId,
    List<String> sessionCardIds,
  ) async {
    final placeholders = List.filled(sessionCardIds.length, '?').join(', ');
    final row = await _db
        .customSelect(
          'SELECT COUNT(DISTINCT c.back_folded) AS n FROM card c'
          ' JOIN deck d ON d.id = c.deck_id'
          ' JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE d.root_id = ? AND c.delete_batch_id IS NULL'
          ' AND d.delete_batch_id IS NULL'
          ' AND (cs.learned_at IS NOT NULL OR c.id IN ($placeholders))',
          variables: [
            Variable<String>(rootId),
            for (final id in sessionCardIds) Variable<String>(id),
          ],
          readsFrom: {_db.deck, _db.card, _db.cardSchedule},
        )
        .getSingle();
    return row.read<int>('n');
  }

  /// Ends every open session: `user_exit` when it started on or after
  /// [startOfToday], `interrupted` when it started on an earlier local day
  /// (BR-STUDY-072; spec D2).
  Future<void> closeOpenSessions({
    required DateTime now,
    required DateTime startOfToday,
  }) => _db.customUpdate(
    'UPDATE study_session SET status = ?, ended_at = ?,'
    ' end_reason = CASE WHEN started_at >= ? THEN ? ELSE ? END'
    ' WHERE status = ?',
    variables: [
      Variable<String>(SessionStatus.abandoned.code),
      Variable<DateTime>(now),
      Variable<DateTime>(startOfToday),
      Variable<String>(SessionEndReason.userExit.code),
      Variable<String>(SessionEndReason.interrupted.code),
      Variable<String>(SessionStatus.inProgress.code),
    ],
    updates: {_db.studySession},
    updateKind: UpdateKind.update,
  );

  Future<void> insertSession(StudySessionCompanion row) =>
      _db.into(_db.studySession).insert(row);
}
