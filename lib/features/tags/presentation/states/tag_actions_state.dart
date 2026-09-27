import 'package:flutter/foundation.dart';

/// How a tag write ended, as screen 05 tells it (FE-B2 spec D8, §6).
enum TagWriteResult {
  /// Written; the catalog updates itself.
  done,

  /// The tag was deleted elsewhere in the meantime (`tagGone`, E3).
  gone,

  /// The name no longer plans the same way: a merge target appeared or
  /// went, or the name breaks a rule. The rename dialog opens again.
  replan,

  /// The database refused; nothing changed (`opError`, E4, E5).
  failed,
}

/// The tags whose write is running: their rows spin instead of ⋮ (`busy`).
@immutable
final class TagActionsState {
  const TagActionsState({this.busyTagIds = const {}});

  final Set<String> busyTagIds;

  bool isBusy(String tagId) => busyTagIds.contains(tagId);
}
