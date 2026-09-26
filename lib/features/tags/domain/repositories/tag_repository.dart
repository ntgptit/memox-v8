import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

/// The one implementation is `TagRepositoryImpl` (data layer). The contract
/// exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
///
/// Every method runs in one transaction and joins the caller's when there is
/// one: the card data layer calls it inside the card's own transaction. An
/// empty set of cards writes nothing and answers `Ok`.
abstract interface class TagRepository {
  /// Links the tag named [name] to every card of [cardIds]: the tag with the
  /// same folded name is reused, or created (BR-TAG-001). A card that already
  /// carries it is left as it is. When one card would pass 10 tags, the whole
  /// batch is refused and nothing is written (BR-TAG-002, BR-CARD-011).
  Future<Outcome<void, TagRejection>> attachByName({
    required Set<String> cardIds,
    required String name,
    DateTime? now,
  });

  /// Unlinks the tag [tagId] from every card of [cardIds]. A card without the
  /// tag is not an error; the tag itself stays (BR-TAG-003).
  Future<Outcome<void, TagRejection>> detach({
    required Set<String> cardIds,
    required String tagId,
  });

  /// Makes the tags of [cardId] exactly [names], one per folded name, with
  /// the rules of [attachByName].
  Future<Outcome<void, TagRejection>> replaceForCard({
    required String cardId,
    required List<String> names,
    DateTime? now,
  });

  /// UC-TAG-001 steps 1-3 and 6: every tag of the local profile with the
  /// active cards carrying it, in [deckId] when given and in the library
  /// otherwise, by folded name then id; again after every change of the
  /// tags, their links or the cards (BR-TAG-003, BR-TAG-010). A
  /// [searchTerm] keeps the tags whose folded name holds its fold.
  Stream<List<TagCount>> watchTagCounts({
    String? deckId,
    String searchTerm = '',
  });
}
