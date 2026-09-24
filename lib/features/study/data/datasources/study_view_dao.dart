import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// A session row with its deck's name and its root's scheduler code.
typedef SessionViewRow = ({
  StudySession session,
  String deckName,
  String schedulerType,
});

/// The rows of a round, done and in all.
typedef RoundCounts = ({int completed, int total});

/// The counts a session's summary shows (spec D11).
typedef SummaryCounts = ({int cardCount, int learnedCount, int wrongCount});

/// The reads of the study screens (spec §8). They write nothing
/// (BR-STUDY-075), return Drift rows and records, never domain values.
final class StudyViewDao {
  StudyViewDao(this._db);

  final AppDatabase _db;

  /// [sessionId]'s row, with its deck's name and its root's scheduler; null
  /// once the session is gone. Emits again on every write the session
  /// screen can see: the session, its queue, its decks, cards, schedules and
  /// logs.
  Stream<SessionViewRow?> watchSessionRow(String sessionId) => _db
      .customSelect(
        'SELECT s.*, d.name AS deck_name, r.scheduler_type AS root_scheduler'
        ' FROM study_session s JOIN deck d ON d.id = s.deck_id'
        ' JOIN deck r ON r.id = s.root_id WHERE s.id = ?',
        variables: [Variable<String>(sessionId)],
        readsFrom: {
          _db.studySession,
          _db.studyQueueItems,
          _db.deck,
          _db.card,
          _db.cardSchedule,
          _db.reviewLog,
        },
      )
      .watchSingleOrNull()
      .map(
        (row) => row == null
            ? null
            : (
                session: _db.studySession.map(row.data),
                deckName: row.read<String>('deck_name'),
                schedulerType: row.read<String>('root_scheduler'),
              ),
      );

  Future<CardRow?> cardRow(String cardId) => (_db.select(
    _db.card,
  )..where((card) => card.id.equals(cardId))).getSingleOrNull();

  /// The modes [sessionId] has rows in.
  Future<Set<String>> modesOf(String sessionId) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT mode FROM study_queue_items WHERE session_id = ?',
          variables: [Variable<String>(sessionId)],
          readsFrom: {_db.studyQueueItems},
        )
        .get();
    return {for (final row in rows) row.read<String>('mode')};
  }

  Future<RoundCounts> roundCounts(
    String sessionId,
    String mode,
    int round,
  ) async {
    final row = await _db
        .customSelect(
          "SELECT COALESCE(SUM(status = 'completed'), 0) AS completed,"
          ' COUNT(*) AS total FROM study_queue_items'
          ' WHERE session_id = ? AND mode = ? AND round = ?',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            Variable<int>(round),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingle();
    return (
      completed: row.read<int>('completed'),
      total: row.read<int>('total'),
    );
  }

  /// The distinct cards of [sessionId]'s queue, those of them now learned,
  /// and its logs whose action is one of [lapseActions].
  Future<SummaryCounts> summaryCounts(
    String sessionId, {
    required List<String> lapseActions,
  }) async {
    final lapses = List.filled(lapseActions.length, '?').join(', ');
    final row = await _db
        .customSelect(
          'SELECT'
          ' (SELECT COUNT(DISTINCT card_id) FROM study_queue_items'
          '  WHERE session_id = ?) AS card_count,'
          ' (SELECT COUNT(DISTINCT q.card_id) FROM study_queue_items q'
          '  JOIN card_schedule cs ON cs.card_id = q.card_id'
          '  WHERE q.session_id = ? AND cs.learned_at IS NOT NULL)'
          '  AS learned_count,'
          ' (SELECT COUNT(*) FROM review_log WHERE session_id = ?'
          '  AND action IN ($lapses)) AS wrong_count',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(sessionId),
            Variable<String>(sessionId),
            for (final action in lapseActions) Variable<String>(action),
          ],
          readsFrom: {_db.studyQueueItems, _db.cardSchedule, _db.reviewLog},
        )
        .getSingle();
    return (
      cardCount: row.read<int>('card_count'),
      learnedCount: row.read<int>('learned_count'),
      wrongCount: row.read<int>('wrong_count'),
    );
  }
}
