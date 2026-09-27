import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 steps 1-3: the tag catalog, every tag of the library with its
/// active cards, under the search, again after every change (BR-TAG-003).
final class WatchTagCatalogUseCase {
  const WatchTagCatalogUseCase(this._tags);

  final TagRepository _tags;

  Stream<List<TagCount>> call({String searchTerm = ''}) =>
      _tags.watchTagCounts(searchTerm: searchTerm);
}
