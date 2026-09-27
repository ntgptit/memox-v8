import 'package:memox/core/text/folded_text.dart';

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

/// The catalog's search, done on a list already read (BR-TAG-003).
extension TagCountsMatching on List<TagCount> {
  /// The tags whose folded name holds [term]'s fold, in order: the fold the
  /// store writes and searches with. A blank term keeps every tag.
  List<TagCount> matching(String term) {
    final folded = foldText(term);
    if (folded.isEmpty) return this;
    return [
      for (final tag in this)
        if (foldText(tag.name).contains(folded)) tag,
    ];
  }
}
