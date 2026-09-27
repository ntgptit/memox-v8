import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/presentation/providers/delete_tag_use_case_provider.dart';
import 'package:memox/features/tags/presentation/providers/plan_tag_rename_use_case_provider.dart';
import 'package:memox/features/tags/presentation/providers/rename_tag_use_case_provider.dart';
import 'package:memox/features/tags/presentation/states/tag_actions_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_actions_controller.g.dart';

/// Screen 05's writes (UC-TAG-001 steps 4-5, A1, A3): the rename plan, the
/// rename or merge, the delete, and the rows they keep busy.
@riverpod
class TagActionsController extends _$TagActionsController {
  @override
  TagActionsState build() => const TagActionsState();

  /// What renaming [tagId] to [name] would do (FE-B2 spec D8). A database
  /// `Failure` is thrown through; the dialog keeps its last plan.
  Future<Outcome<TagRenamePlan, TagRejection>> planRename({
    required String tagId,
    required String name,
  }) => ref.read(planTagRenameUseCaseProvider)(tagId: tagId, name: name);

  /// Renames [tagId], or merges it into [mergeIntoTagId], the target the
  /// person confirmed (BR-TAG-006, BR-TAG-007).
  Future<TagWriteResult> rename({
    required String tagId,
    required String name,
    String? mergeIntoTagId,
  }) => _write(
    tagId,
    () => ref.read(renameTagUseCaseProvider)(
      tagId: tagId,
      name: name,
      mergeIntoTagId: mergeIntoTagId,
    ),
  );

  /// Deletes [tagId] and its links; no card is touched (BR-TAG-008).
  Future<TagWriteResult> delete(String tagId) =>
      _write(tagId, () => ref.read(deleteTagUseCaseProvider)(tagId: tagId));

  Future<TagWriteResult> _write(
    String tagId,
    Future<Outcome<void, TagRejection>> Function() write,
  ) async {
    state = TagActionsState(busyTagIds: {...state.busyTagIds, tagId});
    try {
      return switch (await write()) {
        Ok() => TagWriteResult.done,
        Rejected(reason: TagRejection.notFound) => TagWriteResult.gone,
        Rejected() => TagWriteResult.replan,
      };
    } on Failure {
      return TagWriteResult.failed;
    } finally {
      if (ref.mounted) {
        state = TagActionsState(
          busyTagIds: {...state.busyTagIds}..remove(tagId),
        );
      }
    }
  }
}
