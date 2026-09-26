/// Which cards of a deck the list shows (UC-CARD-001, IT-ORG-005).
enum CardListFilter {
  all,

  /// Learned and due at the list's now (BR-STUDY-047).
  due,

  /// Not learned yet (BR-CARD-007).
  newCards,
  flagged,
}

/// How the list is ordered (IT-ORG-003).
enum CardListSort {
  /// `(created_at DESC, id DESC)`.
  newest,

  /// Soonest `due_at` first, New cards last, then as [newest].
  dueFirst,
}

/// What the person asked the card list for. The list, its counts and Select
/// all read the same query (BR-CARD-012).
final class CardListQuery {
  const CardListQuery({
    this.filter = CardListFilter.all,
    this.sort = CardListSort.newest,
    this.searchTerm = '',
    this.tagIds = const {},
  });

  final CardListFilter filter;
  final CardListSort sort;

  /// As typed: folded before it is matched, and a blank term searches
  /// nothing out.
  final String searchTerm;

  /// A card passes when it carries any of these tags (BR-TAG-004); none
  /// lets every card through. An id that no longer exists matches no card.
  final Set<String> tagIds;
}
