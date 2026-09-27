import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 step 4 and A1: renames a tag, or merges it into the tag the
/// person confirmed (BR-TAG-006, BR-TAG-007).
final class RenameTagUseCase {
  const RenameTagUseCase(this._tags);

  final TagRepository _tags;

  Future<Outcome<void, TagRejection>> call({
    required String tagId,
    required String name,
    String? mergeIntoTagId,
  }) =>
      _tags.renameTag(tagId: tagId, name: name, mergeIntoTagId: mergeIntoTagId);
}
