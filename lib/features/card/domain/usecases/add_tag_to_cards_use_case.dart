import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-CARD-001 A6, A8: the tag named [tagName] on every card given, reused
/// by its folded name or created (BR-TAG-001, BR-CARD-011).
final class AddTagToCardsUseCase {
  const AddTagToCardsUseCase(this._tags);

  final TagRepository _tags;

  Future<Outcome<void, TagRejection>> call({
    required Set<String> cardIds,
    required String tagName,
  }) => _tags.attachByName(cardIds: cardIds, name: tagName);
}
