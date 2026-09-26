import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

/// A session row with its deck's name and its root's scheduler code.
typedef SessionViewRow = ({
  StudySession session,
  String deckName,
  String schedulerType,
});

/// The rows of a round, done and in all.
typedef RoundCounts = ({int completed, int total});

/// The session the Study tab's Resume card offers, with the name of the deck
/// it was opened on.
typedef ResumableRow = ({StudySession session, String deckName});

/// The counts a session's summary shows (spec D11).
typedef SummaryCounts = ({
  int cardCount,
  int learnedCount,
  int wrongCount,
  int answeredCount,
  int turnCount,
});

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

/// A card Browse showed in a round: its faces for looking back.
typedef TrailRecord = ({
  String cardId,
  String front,
  String back,
  String? pronunciation,
  String? example,
});

/// The sessions Continue and Resume may take up (BR-STUDY-075), over
/// `study_session s`, its deck `d` and its root `r`: open, started on or after
/// the one variable, the start of today, at the root's generation, out of the
/// Trash and with a queue row left (Study Home spec D6).
const _resumable =
    ' FROM study_session s JOIN deck d ON d.id = s.deck_id'
    ' JOIN deck r ON r.id = s.root_id'
    " WHERE s.status = 'in_progress' AND s.started_at >= ?"
    ' AND s.generation = r.generation'
    ' AND d.delete_batch_id IS NULL AND r.delete_batch_id IS NULL'
    ' AND EXISTS (SELECT 1 FROM study_queue_items q WHERE q.session_id = s.id)';

/// The newest of them; of two started at once, the higher id.
const _newestFirst = ' ORDER BY s.started_at DESC, s.id DESC LIMIT 1';

/// The reads of the study screens (spec §8). They write nothing
/// (BR-STUDY-075), return Drift rows and records, never domain values.
final class StudyViewDao {
  StudyViewDao(this._db);

  final AppDatabase _db;

  /// [sessionId]'s row, with its deck's name and its root's scheduler; null
  /// once the session is gone or its deck or root is in the Trash
  /// (BR-TRASH-002). Emits again on every write the session screen can see:
  /// the session, its queue, its decks, cards, schedules and logs.
  Stream<SessionViewRow?> watchSessionRow(String sessionId) => _db
      .customSelect(
        'SELECT s.*, d.name AS deck_name, r.scheduler_type AS root_scheduler'
        ' FROM study_session s JOIN deck d ON d.id = s.deck_id'
        ' JOIN deck r ON r.id = s.root_id WHERE s.id = ?'
        ' AND d.delete_batch_id IS NULL AND r.delete_batch_id IS NULL',
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

  /// The newest open session Continue can take up (BR-STUDY-075): of
  /// [deckId] when given, of any deck otherwise (the Study tab's Resume
  /// card); null when none may be taken up.
  Future<ResumableRow?> resumableSessionRow({
    String? deckId,
    required DateTime startOfToday,
  }) async {
    final byDeck = deckId == null ? '' : ' AND s.deck_id = ?';
    final row = await _db
        .customSelect(
          'SELECT s.*, d.name AS deck_name$_resumable$byDeck$_newestFirst',
          variables: [
            Variable<DateTime>(startOfToday),
            if (deckId != null) Variable<String>(deckId),
          ],
          readsFrom: {_db.studySession, _db.deck, _db.studyQueueItems},
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      session: _db.studySession.map(row.data),
      deckName: row.read<String>('deck_name'),
    );
  }

  /// Every root deck with the workload of its whole tree: the statement the
  /// Library's root level reads (BR-STUDY-076, BR-STUDY-068).
  Future<List<DeckTileRow>> rootDeckRows({
    required DateTime now,
    required DateTime startOfToday,
  }) => _db.deckLevelOfRoots(startOfToday, now).get();

  /// The earliest due date after [now] of a learned card out of the Trash
  /// (Study Home spec D4); null when none waits.
  Future<DateTime?> nextDueAt({required DateTime now}) async {
    final row = await _db
        .customSelect(
          'SELECT MIN(cs.due_at) AS next_due_at FROM card c'
          ' JOIN deck k ON k.id = c.deck_id'
          ' JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL'
          ' AND cs.learned_at IS NOT NULL AND cs.due_at > ?',
          variables: [Variable<DateTime>(now)],
          readsFrom: {_db.card, _db.deck, _db.cardSchedule},
        )
        .getSingle();
    return row.read<DateTime?>('next_due_at');
  }

  /// Fires once when listened to, then after every write to a table the
  /// Study tab reads: decks, cards, schedules, sessions and queues
  /// (`tableChanges`, Study Home spec D7).
  Stream<void> homeChanges() => tableChanges(_db, [
    _db.deck,
    _db.card,
    _db.cardSchedule,
    _db.studySession,
    _db.studyQueueItems,
  ]);

  Future<CardRow?> cardRow(String cardId) =>
      (_db.select(_db.card)..where(
            (card) => card.id.equals(cardId) & card.deleteBatchId.isNull(),
          ))
          .getSingleOrNull();

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
  /// shown (graded modes spec §9). A card in the Trash is left out
  /// (BR-TRASH-002), which blocks the question as a deleted card does; a
  /// delete closes such a session anyway (trash spec D7).
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
          ' AND c.delete_batch_id IS NULL ORDER BY o.slot',
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
          ' AND c.delete_batch_id IS NULL'
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

  /// The completed rows of [round] of [mode], in the order served
  /// (BR-STUDY-048: the trail keeps that order). A card in the Trash is
  /// left out (BR-TRASH-002).
  Future<List<TrailRecord>> trail(
    String sessionId,
    String mode,
    int round,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT c.id, c.front, c.back, c.pronunciation, c.example'
          ' FROM study_queue_items q JOIN card c ON c.id = q.card_id'
          ' AND c.delete_batch_id IS NULL'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
          " AND q.status = 'completed' AND q.position >= 0"
          ' ORDER BY q.position',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            Variable<int>(round),
          ],
          readsFrom: {_db.studyQueueItems, _db.card},
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('id'),
          front: row.read<String>('front'),
          back: row.read<String>('back'),
          pronunciation: row.read<String?>('pronunciation'),
          example: row.read<String?>('example'),
        ),
    ];
  }

  /// The distinct cards of [sessionId]'s queue, those of them now learned,
  /// its logs whose action is one of [lapseActions], and its graded turns
  /// and the distinct cards they answered (FE-A6 D11).
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
          ' (SELECT COUNT(DISTINCT card_id) FROM review_log'
          '  WHERE session_id = ?) AS answered_count,'
          ' (SELECT COUNT(*) FROM review_log WHERE session_id = ?)'
          '  AS turn_count,'
          ' (SELECT COUNT(*) FROM review_log WHERE session_id = ?'
          '  AND action IN ($lapses)) AS wrong_count',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(sessionId),
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
      answeredCount: row.read<int>('answered_count'),
      turnCount: row.read<int>('turn_count'),
    );
  }
}
