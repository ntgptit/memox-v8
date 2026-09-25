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

/// An option of a `guess` question: the option card and its meaning.
typedef OptionRecord = ({String cardId, String back});

/// A pair of a `match` board: its card's two sides, whether it is matched in
/// the round, and its meaning slot.
typedef BoardPairRecord = ({
  String cardId,
  String front,
  String back,
  bool isCompleted,
  int? meaningSlot,
});

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
          _db.studyGuessOptions,
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

  /// [deckId]'s row, unless it is gone or in the Trash. Emits again on every
  /// write the Study Entry can see: decks and their options, cards,
  /// schedules, sessions and queues.
  Stream<Deck?> watchDeckRow(String deckId) => _db
      .customSelect(
        'SELECT * FROM deck WHERE id = ? AND delete_batch_id IS NULL',
        variables: [Variable<String>(deckId)],
        readsFrom: {
          _db.deck,
          _db.card,
          _db.cardSchedule,
          _db.appSettings,
          _db.studySession,
          _db.studyQueueItems,
        },
      )
      .watchSingleOrNull()
      .map((row) => row == null ? null : _db.deck.map(row.data));

  /// The newest open session of [deckId] that Continue can take up
  /// (BR-STUDY-075): started on or after [startOfToday], at its root's
  /// generation, with at least one queue row.
  Future<String?> resumableSessionId(
    String deckId, {
    required DateTime startOfToday,
  }) async {
    final row = await _db
        .customSelect(
          'SELECT s.id FROM study_session s JOIN deck r ON r.id = s.root_id'
          " WHERE s.deck_id = ? AND s.status = 'in_progress'"
          ' AND s.started_at >= ? AND s.generation = r.generation'
          ' AND EXISTS (SELECT 1 FROM study_queue_items q'
          '  WHERE q.session_id = s.id)'
          ' ORDER BY s.started_at DESC LIMIT 1',
          variables: [
            Variable<String>(deckId),
            Variable<DateTime>(startOfToday),
          ],
          readsFrom: {_db.studySession, _db.deck, _db.studyQueueItems},
        )
        .getSingleOrNull();
    return row?.read<String>('id');
  }

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

  /// The options of [cardId]'s question in [round] of `guess`, in the order
  /// shown (graded modes spec §9).
  Future<List<OptionRecord>> guessOptions(
    String sessionId,
    int round,
    String cardId,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT o.option_card_id, c.back FROM study_guess_options o'
          ' JOIN card c ON c.id = o.option_card_id'
          ' WHERE o.session_id = ? AND o.round = ? AND o.card_id = ?'
          ' ORDER BY o.slot',
          variables: [
            Variable<String>(sessionId),
            Variable<int>(round),
            Variable<String>(cardId),
          ],
          readsFrom: {_db.studyGuessOptions, _db.card},
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('option_card_id'),
          back: row.read<String>('back'),
        ),
    ];
  }

  /// The pairs of [round] of [mode] at positions [from] to [to], a board, in
  /// position order (graded modes spec §9).
  Future<List<BoardPairRecord>> boardPairs(
    String sessionId,
    String mode,
    int round, {
    required int from,
    required int to,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT q.card_id, q.status, q.meaning_slot, c.front, c.back'
          ' FROM study_queue_items q JOIN card c ON c.id = q.card_id'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
          ' AND q.position BETWEEN ? AND ? ORDER BY q.position',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            Variable<int>(round),
            Variable<int>(from),
            Variable<int>(to),
          ],
          readsFrom: {_db.studyQueueItems, _db.card},
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('card_id'),
          front: row.read<String>('front'),
          back: row.read<String>('back'),
          isCompleted: row.read<String>('status') == 'completed',
          meaningSlot: row.read<int?>('meaning_slot'),
        ),
    ];
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
