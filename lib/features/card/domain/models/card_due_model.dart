import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/srs/domain/models/due_state_model.dart';

/// Which way a card's next review lies from today.
enum CardDueKind { newCard, overdue, today, later }

/// When a card comes back, as its row in the card list says it (screen 07):
/// "New", "Due today", "In N d", "N d overdue". Derived on read, never
/// stored; days are counted on calendar dates, like a deck's overdue run
/// (BR-STUDY-067).
final class CardDue {
  const CardDue._(this.kind, this.days);

  const CardDue.newCard() : this._(CardDueKind.newCard, 0);
  const CardDue.today() : this._(CardDueKind.today, 0);
  const CardDue.overdue(int days) : this._(CardDueKind.overdue, days);
  const CardDue.later(int days) : this._(CardDueKind.later, days);

  /// From the card's schedule at the moment of the read: the set of
  /// BR-STUDY-068 through `dueStateOf` (the one Dart copy of the rule,
  /// DEV-221), then the calendar count of days overdue or ahead.
  /// [startOfToday] is the start of the local day the list reads at.
  factory CardDue.of({
    required DateTime? learnedAt,
    required DateTime? dueAt,
    required DateTime now,
    required DateTime startOfToday,
  }) => switch (dueStateOf(
    learnedAt: learnedAt,
    dueAt: dueAt,
    now: now,
    startOfToday: startOfToday,
  )) {
    DueState.newCard => const CardDue.newCard(),
    DueState.dueToday => const CardDue.today(),
    DueState.overdue => CardDue.overdue(
      DeckScheduleStatus.overdueDays(dueAt, startOfToday),
    ),
    // The same calendar count, from today forward to the due date; a
    // learned card with no due date rests with no day to count.
    DueState.scheduled => CardDue.later(
      dueAt == null ? 0 : DeckScheduleStatus.overdueDays(startOfToday, dueAt),
    ),
  };

  final CardDueKind kind;

  /// Calendar days overdue or ahead; 0 for new and today.
  final int days;

  @override
  bool operator ==(Object other) =>
      other is CardDue && other.kind == kind && other.days == days;

  @override
  int get hashCode => Object.hash(kind, days);
}
