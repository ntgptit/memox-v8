import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';

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

  /// [isLearned] is `learned_at` set (BR-CARD-007); [startOfToday] is the
  /// start of the local day the list reads at.
  factory CardDue.of({
    required bool isLearned,
    required DateTime? dueAt,
    required DateTime startOfToday,
  }) {
    if (!isLearned || dueAt == null) return const CardDue.newCard();
    if (dueAt.isBefore(startOfToday)) {
      return CardDue.overdue(
        DeckScheduleStatus.overdueDays(dueAt, startOfToday),
      );
    }
    // The same calendar count, from today forward to the due date.
    final ahead = DeckScheduleStatus.overdueDays(startOfToday, dueAt);
    return ahead == 0 ? const CardDue.today() : CardDue.later(ahead);
  }

  final CardDueKind kind;

  /// Calendar days overdue or ahead; 0 for new and today.
  final int days;

  @override
  bool operator ==(Object other) =>
      other is CardDue && other.kind == kind && other.days == days;

  @override
  int get hashCode => Object.hash(kind, days);
}
