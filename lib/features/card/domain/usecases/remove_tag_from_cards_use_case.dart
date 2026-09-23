import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-CARD-001 A8: the tag off every card given; the tag itself stays.
final class RemoveTagFromCardsUseCase {
  const RemoveTagFromCardsUseCase(this._tags);

  final TagRepository _tags;

  Future<Outcome<void, TagRejection>> call({
    required Set<String> cardIds,
    required String tagId,
  }) => _tags.detach(cardIds: cardIds, tagId: tagId);
}
