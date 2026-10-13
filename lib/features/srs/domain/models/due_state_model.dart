/// The one of four sets a card's schedule puts it in (BR-STUDY-068,
/// BR-STUDY-051, BR-CARD-007): derived on read from `learned_at` and
/// `due_at` against the moment of the read, never stored. The four partition
/// a deck's cards; a session's Reviewing set is [overdue] with [dueToday].
enum DueState {
  /// Not learned yet (BR-CARD-007), whatever `due_at` says.
  newCard,

  /// Learned, due before the start of the local day (BR-STUDY-067).
  overdue,

  /// Learned, due from the start of the local day up to now.
  dueToday,

  /// Learned, resting until it falls due: due after now, or with no due date
  /// at all (a row that breaks invariant 24 is learned and not due, as the
  /// counts "total − New − Due" already placed it).
  scheduled,
}

/// BR-CARD-007: a card not learned yet is new, in both schedulers.
bool isNewCard(DateTime? learnedAt) => learnedAt == null;

/// The one Dart copy of the rule (DEV-221); `CardDueSql` (core/database) is
/// its SQL twin, and `due_state_parity_test.dart` keeps them equal.
/// [startOfToday] is the local day's start at [now] (BR-STUDY-074).
DueState dueStateOf({
  required DateTime? learnedAt,
  required DateTime? dueAt,
  required DateTime now,
  required DateTime startOfToday,
}) {
  if (isNewCard(learnedAt)) return DueState.newCard;
  if (dueAt == null || dueAt.isAfter(now)) return DueState.scheduled;
  if (dueAt.isBefore(startOfToday)) return DueState.overdue;
  return DueState.dueToday;
}

/// BR-STUDY-068: the cards resting until they fall due, from the same
/// snapshot as the other three sets; the four add up to [cardCount].
int scheduledCountOf({
  required int cardCount,
  required int newCount,
  required int dueCount,
}) => cardCount - newCount - dueCount;
