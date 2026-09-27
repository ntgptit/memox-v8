import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 step 6: every tag with the active cards of [deckId] carrying
/// it, for the card list's tag filter (tag management spec D3).
final class WatchDeckTagCountsUseCase {
  const WatchDeckTagCountsUseCase(this._tags);

  final TagRepository _tags;

  Stream<List<TagCount>> call({required String deckId}) =>
      _tags.watchTagCounts(deckId: deckId);
}
