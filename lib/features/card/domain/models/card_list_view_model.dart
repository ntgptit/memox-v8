import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';

/// One row of the card list.
final class CardListItem {
  const CardListItem({
    required this.id,
    required this.front,
    required this.back,
    required this.isFlagged,
    required this.dueAt,
    required this.displayStatus,
    required this.due,
    required this.tags,
  });

  final String id;
  final String front;
  final String back;
  final bool isFlagged;

  /// Null for a card not learned yet.
  final DateTime? dueAt;
  final CardDisplayStatus displayStatus;

  /// When the card comes back, from its schedule and the list's day.
  final CardDue due;

  /// Its tags, by folded name then id (BR-TAG-001).
  final List<TagEntity> tags;
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

/// How many of the deck's active cards show each display state
/// (BR-CARD-008, BR-SRS-013), whatever the search and the filter: the deck's
/// progress, not the list's.
final class CardStatusCounts {
  const CardStatusCounts({
    required this.newCards,
    required this.beginning,
    required this.reviewing,
    required this.mastered,
  });

  final int newCards;
  final int beginning;
  final int reviewing;
  final int mastered;

  int get total => newCards + beginning + reviewing + mastered;
}

/// The card list as it stands: a window of items and the filter counts.
final class CardListView {
  const CardListView({
    required this.items,
    required this.hasMore,
    required this.counts,
    required this.statusCounts,
  });

  final List<CardListItem> items;

  /// More cards follow the window; the list asks for a larger one to see
  /// them.
  final bool hasMore;
  final CardListCounts counts;
  final CardStatusCounts statusCounts;
}
