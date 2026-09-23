import 'package:memox/features/card/domain/models/card_display_status_model.dart';

/// One row of the card list.
final class CardListItem {
  const CardListItem({
    required this.id,
    required this.front,
    required this.back,
    required this.isFlagged,
    required this.dueAt,
    required this.displayStatus,
  });

  final String id;
  final String front;
  final String back;
  final bool isFlagged;

  /// Null for a card not learned yet.
  final DateTime? dueAt;
  final CardDisplayStatus displayStatus;
}

/// How many cards each filter would show under the current search, whatever
/// filter is picked (IT-ORG-005).
final class CardListCounts {
  const CardListCounts({
    required this.all,
    required this.due,
    required this.newCards,
    required this.flagged,
  });

  final int all;
  final int due;
  final int newCards;
  final int flagged;
}

/// The card list as it stands: a window of items and the filter counts.
final class CardListView {
  const CardListView({
    required this.items,
    required this.hasMore,
    required this.counts,
  });

  final List<CardListItem> items;

  /// More cards follow the window; the list asks for a larger one to see
  /// them.
  final bool hasMore;
  final CardListCounts counts;
}
