import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/card_due_sql.dart';
import 'package:memox/core/database/table_changes.dart';

part 'study_view_dao.g.dart';

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

/// The reads of the study screens (spec §8, `study_view_queries.drift`).
/// They write nothing (BR-STUDY-075), return Drift rows and records, never
/// domain values.
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/deck_queries.drift',
    'package:memox/core/database/queries/study_view_queries.drift',
    'package:memox/core/database/queries/live_row_queries.drift',
  },
)
final class StudyViewDao extends DatabaseAccessor<AppDatabase>
    with _$StudyViewDaoMixin {
  StudyViewDao(super.attachedDatabase);

  /// [sessionId]'s row, with its deck's name and its root's scheduler; null
  /// once the session is gone or its deck or root is in the Trash
  /// (BR-TRASH-002). Emits again on every write the session screen can see:
  /// the session, its queue, its decks, cards, schedules and logs, through
  /// `tableChanges`, since the read itself touches fewer tables.
  Stream<SessionViewRow?> watchSessionRow(String sessionId) =>
      tableChanges(attachedDatabase, [
        attachedDatabase.studySession,
        attachedDatabase.studyQueueItems,
        attachedDatabase.studyGuessOptions,
        attachedDatabase.deck,
        attachedDatabase.card,
        attachedDatabase.cardSchedule,
        attachedDatabase.reviewLog,
      ]).asyncMap((_) async {
        final row = await sessionWithDeckOf(sessionId).getSingleOrNull();
        if (row == null) return null;
        return (
          session: row.s,
          deckName: row.deckName,
          schedulerType: row.rootScheduler!,
        );
      });

  /// [deckId]'s row, unless it is gone or in the Trash. Emits again on every
  /// write the Study Entry can see: decks and their options, cards,
  /// schedules, sessions and queues, through `tableChanges`, since the read
  /// itself touches only `deck`.
  Stream<Deck?> watchDeckRow(String deckId) => tableChanges(attachedDatabase, [
    attachedDatabase.deck,
    attachedDatabase.card,
    attachedDatabase.cardSchedule,
    attachedDatabase.appSettings,
    attachedDatabase.studySession,
    attachedDatabase.studyQueueItems,
  ]).asyncMap((_) => liveDeckRow(deckId).getSingleOrNull());

  /// The newest open session Continue can take up (BR-STUDY-075): of
  /// [deckId] when given, of any deck otherwise (the Study tab's Resume
  /// card); null when none may be taken up.
  Future<ResumableRow?> resumableSessionRow({
    String? deckId,
    required DateTime startOfToday,
  }) async {
    if (deckId == null) {
      final row = await resumableSession(startOfToday).getSingleOrNull();
      return row == null ? null : (session: row.s, deckName: row.deckName);
    }
    final row = await resumableSessionOfDeck(
      startOfToday,
      deckId,
    ).getSingleOrNull();
    return row == null ? null : (session: row.s, deckName: row.deckName);
  }

  /// Every root deck with the workload of its whole tree: the statement the
  /// Library's root level reads (BR-STUDY-076, BR-STUDY-068).
  Future<List<DeckTileRow>> rootDeckRows({
    required DateTime now,
    required DateTime startOfToday,
  }) => deckLevelOfRoots(
    (c, k, cs) => CardDueSql.isNew(cs),
    (c, k, cs) => CardDueSql.isOverdue(cs, startOfToday),
    (c, k, cs) =>
        CardDueSql.isDueToday(cs, now: now, startOfToday: startOfToday),
    (c, k, cs) => CardDueSql.isDue(cs, now),
  ).get();

  /// The earliest due date after [now] of a learned card out of the Trash
  /// (Study Home spec D4); null when none waits.
  Future<DateTime?> nextDueAt({required DateTime now}) =>
      nextDueAtAfter((c, k, cs) => CardDueSql.isScheduled(cs, now)).getSingle();

  /// Fires once when listened to, then after every write to a table the
  /// Study tab reads: decks, cards, schedules, sessions and queues
  /// (`tableChanges`, Study Home spec D7).
  Stream<void> homeChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.deck,
    attachedDatabase.card,
    attachedDatabase.cardSchedule,
    attachedDatabase.studySession,
    attachedDatabase.studyQueueItems,
  ]);

  Future<CardRow?> cardRow(String cardId) =>
      liveCardRow(cardId).getSingleOrNull();

  /// The modes [sessionId] has rows in.
  Future<Set<String>> modesOf(String sessionId) async =>
      (await modesOfSession(sessionId).get()).toSet();

  /// The rows of [round] of [mode], done and in all.
  Future<RoundCounts> roundCounts(
    String sessionId,
    String mode,
    int round,
  ) async {
    final row = await roundCountsOf(sessionId, mode, round).getSingle();
    return (completed: row.completed, total: row.total);
  }

  /// The options of [cardId]'s question in [round] of `guess`, in the order
  /// shown (graded modes spec §9). A card in the Trash is left out
  /// (BR-TRASH-002), which blocks the question as a deleted card does; a
  /// delete closes such a session anyway (trash spec D7).
  Future<List<OptionRecord>> guessOptions(
    String sessionId,
    int round,
    String cardId,
  ) async => [
    for (final row in await guessOptionsOf(sessionId, round, cardId).get())
      (cardId: row.optionCardId, back: row.back),
  ];

  /// The pairs of [round] of [mode] at positions [from] to [to], a board, in
  /// position order (graded modes spec §9).
  Future<List<BoardPairRecord>> boardPairs(
    String sessionId,
    String mode,
    int round, {
    required int from,
    required int to,
  }) async => [
    for (final row in await boardPairsOf(
      sessionId,
      mode,
      round,
      from,
      to,
    ).get())
      (
        cardId: row.cardId,
        front: row.front,
        back: row.back,
        isCompleted: row.status == 'completed',
        meaningSlot: row.meaningSlot,
      ),
  ];

  /// The completed rows of [round] of [mode], in the order served
  /// (BR-STUDY-048: the trail keeps that order). A card in the Trash is
  /// left out (BR-TRASH-002).
  Future<List<TrailRecord>> trail(
    String sessionId,
    String mode,
    int round,
  ) async => [
    for (final row in await trailOf(sessionId, mode, round).get())
      (
        cardId: row.id,
        front: row.front,
        back: row.back,
        pronunciation: row.pronunciation,
        example: row.example,
      ),
  ];

  /// The distinct cards of [sessionId]'s queue, those of them now learned,
  /// its logs whose action is one of [lapseActions], and its graded turns
  /// and the distinct cards they answered (FE-A6 D11).
  Future<SummaryCounts> summaryCounts(
    String sessionId, {
    required List<String> lapseActions,
  }) async {
    final row = await summaryCountsOf(sessionId, lapseActions).getSingle();
    return (
      cardCount: row.cardCount,
      learnedCount: row.learnedCount,
      wrongCount: row.wrongCount,
      answeredCount: row.answeredCount,
      turnCount: row.turnCount,
    );
  }
}
