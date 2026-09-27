import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 step 4 and A1: what a rename would do, read as the name is
/// typed, so a merge is shown before the commit (BR-TAG-007).
final class PlanTagRenameUseCase {
  const PlanTagRenameUseCase(this._tags);

  final TagRepository _tags;

  Future<Outcome<TagRenamePlan, TagRejection>> call({
    required String tagId,
    required String name,
  }) => _tags.planRename(tagId: tagId, name: name);
}
