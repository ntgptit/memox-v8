/// A tag and the active cards carrying it in the read's scope: the library
/// for the catalog, one deck for the card list's filter (BR-TAG-003; tag
/// management spec D3).
final class TagCount {
  const TagCount({
    required this.id,
    required this.name,
    required this.cardCount,
  });

  final String id;

  /// The canonical name, as stored (BR-TAG-001).
  final String name;

  /// Active cards only: a card in the Trash is not counted (BR-TAG-010).
  final int cardCount;
}
