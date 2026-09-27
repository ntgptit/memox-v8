import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 step 5: deletes a tag and its links; no card is deleted
/// (BR-TAG-008).
final class DeleteTagUseCase {
  const DeleteTagUseCase(this._tags);

  final TagRepository _tags;

  Future<Outcome<void, TagRejection>> call({required String tagId}) =>
      _tags.deleteTag(tagId: tagId);
}
