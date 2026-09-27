import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 step 6: every tag of the library with the active cards of
/// [deckId] carrying it, 0 included, for the card list's tag filter (tag
/// management spec D3).
final class WatchCardTagFilterUseCase {
  const WatchCardTagFilterUseCase(this._tags);

  final TagRepository _tags;

  Stream<List<TagCount>> call({required String deckId}) =>
      _tags.watchTagCounts(deckId: deckId);
}
