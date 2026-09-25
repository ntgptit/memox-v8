import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';

/// A card a session can take, as the data conditions read it.
typedef StudyCardRow = ({String cardId, bool hasExample});

/// The new and the due cards of a subtree, and the next due date.
typedef SubtreeCounts = ({int newCount, int dueCount, DateTime? nextDueAt});

/// The active decks of the subtree of the first variable, walked through
/// `parent_id` (schema.md "Duyệt cây").
const _subtree =
    'WITH RECURSIVE subtree(id) AS ('
    ' SELECT id FROM deck WHERE id = ? AND delete_batch_id IS NULL'
    ' UNION SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id'
    ' WHERE d.delete_batch_id IS NULL)';

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
  /// order.
  Future<List<StudyCardRow>> _subtreeCards(
    String deckId, {
    required String where,
    required String orderBy,
    List<Variable<Object>> variables = const [],
  }) async {
    final rows = await _db
        .customSelect(
          '$_subtree SELECT c.id, c.example IS NOT NULL AS has_example'
          ' FROM card c JOIN card_schedule cs ON cs.card_id = c.id'
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

  /// The new and the due cards of [deckId]'s subtree at [now], and the
  /// earliest `due_at` after [now] (BR-STUDY-051, BR-STUDY-008).
  Future<SubtreeCounts> subtreeCounts(String deckId, DateTime now) async {
    final row = await _db
        .customSelect(
          '$_subtree SELECT'
          ' COUNT(CASE WHEN cs.learned_at IS NULL THEN 1 END) AS new_count,'
          ' COUNT(CASE WHEN cs.learned_at IS NOT NULL AND cs.due_at <= ?'
          '  THEN 1 END) AS due_count,'
          ' MIN(CASE WHEN cs.learned_at IS NOT NULL AND cs.due_at > ?'
          '  THEN cs.due_at END) AS next_due_at'
          ' FROM card c JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE c.deck_id IN (SELECT id FROM subtree)'
          ' AND c.delete_batch_id IS NULL',
          variables: [
            Variable<String>(deckId),
            Variable<DateTime>(now),
            Variable<DateTime>(now),
          ],
          readsFrom: {_db.deck, _db.card, _db.cardSchedule},
        )
        .getSingle();
    return (
      newCount: row.read<int>('new_count'),
      dueCount: row.read<int>('due_count'),
      nextDueAt: row.read<DateTime?>('next_due_at'),
    );
  }

  /// Whether [cardId] has a hint; a blank one is stored as NULL
  /// (BR-CARD-003).
  Future<bool> hasHint(String cardId) async {
    final row = await _db
        .customSelect(
          'SELECT hint IS NOT NULL AS has_hint FROM card WHERE id = ?',
          variables: [Variable<String>(cardId)],
          readsFrom: {_db.card},
        )
        .getSingleOrNull();
    return row?.read<bool>('has_hint') ?? false;
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

  /// Ends as `interrupted` every open session that started before
  /// [startOfToday] (BR-STUDY-072).
  Future<void> closeStaleSessions({
    required DateTime now,
    required DateTime startOfToday,
  }) =>
      (_db.update(_db.studySession)..where(
            (session) =>
                session.status.equals(SessionStatus.inProgress.code) &
                session.startedAt.isSmallerThanValue(startOfToday),
          ))
          .write(
            StudySessionCompanion(
              status: Value(SessionStatus.abandoned.code),
              endReason: Value(SessionEndReason.interrupted.code),
              endedAt: Value(now),
            ),
          );

  Future<void> insertSession(StudySessionCompanion row) =>
      _db.into(_db.studySession).insert(row);

  Future<StudySession?> sessionRow(String id) => (_db.select(
    _db.studySession,
  )..where((session) => session.id.equals(id))).getSingleOrNull();

  Future<void> setCursor(String id, int cursor) =>
      _updateSession(id, StudySessionCompanion(cursor: Value(cursor)));

  Future<void> setCurrentMode(String id, String mode) =>
      _updateSession(id, StudySessionCompanion(currentMode: Value(mode)));

  /// Ends the session as [status], for [reason] when it did not finish its
  /// queue (schema.md's status matrix).
  Future<void> endSession(
    String id, {
    required SessionStatus status,
    SessionEndReason? reason,
    required DateTime now,
  }) => _updateSession(
    id,
    StudySessionCompanion(
      status: Value(status.code),
      endReason: Value(reason?.code),
      endedAt: Value(now),
    ),
  );

  Future<void> _updateSession(String id, StudySessionCompanion values) =>
      (_db.update(
        _db.studySession,
      )..where((session) => session.id.equals(id))).write(values);
}
