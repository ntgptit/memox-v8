import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';

part 'study_session_dao.g.dart';

/// A card a session can take, as the data conditions read it.
typedef StudyCardRow = ({String cardId, bool hasExample});

/// The new and the due cards of a subtree, and the next due date.
typedef SubtreeCounts = ({
  int newCount,
  int dueCount,
  int overdueCount,
  DateTime? nextDueAt,
});

/// Row access for `study_session`, plus the reads of `deck`, `card` and
/// `card_schedule` a session is built from (`study_session_queries.drift`).
/// It returns Drift rows and records, never domain values, and runs inside
/// the caller's transaction.
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/study_session_queries.drift',
    'package:memox/core/database/queries/live_row_queries.drift',
  },
)
final class StudySessionDao extends DatabaseAccessor<AppDatabase>
    with _$StudySessionDaoMixin {
  StudySessionDao(super.attachedDatabase);

  /// The deck [id] names, unless it is in the Trash.
  Future<Deck?> deckRow(String id) => liveDeckRow(id).getSingleOrNull();

  /// The active cards of [deckId] and its whole subtree that are not learned
  /// yet, oldest first (BR-STUDY-051, BR-STUDY-057).
  Future<List<StudyCardRow>> newCards(String deckId) async => [
    for (final row in await newCardsOfSubtree(deckId).get())
      (cardId: row.id, hasExample: row.hasExample),
  ];

  /// The active learned cards of [deckId] and its whole subtree that are due
  /// at [now], earliest due first (BR-STUDY-001, BR-STUDY-002, BR-STUDY-051).
  Future<List<StudyCardRow>> dueCards(String deckId, DateTime now) async => [
    for (final row in await dueCardsOfSubtree(deckId, now).get())
      (cardId: row.id, hasExample: row.hasExample),
  ];

  /// The new and the due cards of [deckId]'s subtree at [now], the due ones
  /// that fell due before [startOfToday] (BR-STUDY-068's boundary; FE-A6
  /// D15), and the earliest `due_at` after [now] (BR-STUDY-051,
  /// BR-STUDY-008).
  Future<SubtreeCounts> subtreeCounts(
    String deckId,
    DateTime now, {
    required DateTime startOfToday,
  }) async {
    final row = await subtreeCountsOf(deckId, now, startOfToday).getSingle();
    return (
      newCount: row.newCount,
      dueCount: row.dueCount,
      overdueCount: row.overdueCount,
      nextDueAt: row.nextDueAt,
    );
  }

  /// The card [id]: a turn is judged on its folded fields (graded modes spec
  /// §7.2). A queue row keeps its card, so the card is there.
  Future<CardRow> cardRow(String id) => liveCardRow(id).getSingle();

  /// Whether [cardId] has a hint; a blank one is stored as NULL
  /// (BR-CARD-003).
  Future<bool> hasHint(String cardId) async =>
      await liveCardHasHint(cardId).getSingleOrNull() ?? false;

  /// The distinct meanings (`back_folded`) of [sessionCardIds] and of the
  /// learned, active cards of [rootId]'s tree: the distractor source of
  /// `guess` (BR-STUDY-038; spec D5).
  Future<int> distinctMeaningCount(
    String rootId,
    List<String> sessionCardIds,
  ) => distinctMeaningCountOf(rootId, sessionCardIds).getSingle();

  /// Ends every open session: `user_exit` when it started on or after
  /// [startOfToday], `interrupted` when it started on an earlier local day
  /// (BR-STUDY-072; spec D2).
  Future<void> closeOpenSessions({
    required DateTime now,
    required DateTime startOfToday,
  }) => closeAllOpenSessions(
    SessionStatus.abandoned.code,
    now,
    startOfToday,
    SessionEndReason.userExit.code,
    SessionEndReason.interrupted.code,
    SessionStatus.inProgress.code,
  );

  /// Ends as `interrupted` every open session that started before
  /// [startOfToday] (BR-STUDY-072).
  Future<void> closeStaleSessions({
    required DateTime now,
    required DateTime startOfToday,
  }) => closeSessionsStartedBefore(
    SessionStatus.abandoned.code,
    SessionEndReason.interrupted.code,
    now,
    SessionStatus.inProgress.code,
    startOfToday,
  );

  Future<void> insertSession(StudySessionCompanion row) => createSession(row);

  Future<StudySession?> sessionRow(String id) =>
      sessionById(id).getSingleOrNull();

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
      updateSessionRow(values, id);
}
