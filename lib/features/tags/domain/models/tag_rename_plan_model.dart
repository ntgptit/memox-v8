import 'package:memox/features/tags/domain/models/tag_count_model.dart';

/// What renaming a tag to a name would do, told before the write
/// (UC-TAG-001 A1; tag management spec D5).
sealed class TagRenamePlan {
  const TagRenamePlan();
}

/// The trimmed name is the stored one: nothing to write.
final class TagRenameUnchanged extends TagRenamePlan {
  const TagRenameUnchanged();
}

/// A new spelling that no other tag folds to; a case-only change is one
/// (BR-TAG-006).
final class TagRenameRename extends TagRenamePlan {
  const TagRenameRename();
}

/// Another tag folds alike: the rename merges into it (BR-TAG-007).
final class TagRenameMerge extends TagRenamePlan {
  const TagRenameMerge({required this.target, required this.mergedCardCount});

  /// The tag that stays, as the catalog lists it.
  final TagCount target;

  /// The distinct active cards carrying the source or the target: what the
  /// target carries once merged (tag management spec D6).
  final int mergedCardCount;
}
