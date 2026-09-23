import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

const _maxDepth = 10;

final class DeckEntity {
  const DeckEntity({
    required this.id,
    required this.name,
    required this.parentId,
    required this.rootId,
    required this.depth,
    required this.contentType,
    required this.schedulerType,
    required this.generation,
    required this.firstAnsweredAt,
    required this.siblingPosition,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? parentId;
  final String rootId;
  final int depth;
  final DeckContentType contentType;
  final SchedulerType? schedulerType; // non-null only when parentId == null
  final int? generation; // non-null only when parentId == null
  final DateTime? firstAnsweredAt;
  final int siblingPosition;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRoot => parentId == null;

  static Outcome<void, DeckRejection> checkName(String name) =>
      name.trim().isEmpty
      ? const Rejected(DeckRejection.blankName)
      : const Ok(null);

  static Outcome<void, DeckRejection> checkCreateSubDeck({
    required int parentDepth,
  }) => parentDepth >= _maxDepth
      ? const Rejected(DeckRejection.depthExceeded)
      : const Ok(null);

  static Outcome<void, DeckRejection> checkCreateCard({
    required DeckContentType parentContentType,
  }) => parentContentType == DeckContentType.deck
      ? const Rejected(DeckRejection.notACardContainer)
      : const Ok(null);

  /// Whether moving `movingId` under `targetParentId` is allowed. The caller
  /// (the repository, inside its transaction) supplies:
  /// - [targetAncestorIds]: the target parent and every ancestor above it, so
  ///   this stays a pure comparison instead of a recursive query.
  /// - [targetDepth]: depth the target parent is at today.
  /// - [subtreeHeight]: how many levels deep the moving subtree goes below
  ///   `movingId` itself (a leaf has height 1).
  static Outcome<void, DeckRejection> checkMove({
    required String movingId,
    required String targetParentId,
    required List<String> targetAncestorIds,
    required int targetDepth,
    required int subtreeHeight,
    required SchedulerType? movingRootScheduler,
    required int? movingRootGeneration,
    required SchedulerType? targetRootScheduler,
    required int? targetRootGeneration,
  }) {
    if (targetParentId == movingId || targetAncestorIds.contains(movingId)) {
      return const Rejected(DeckRejection.movingIntoOwnSubtree);
    }
    if (targetDepth + subtreeHeight > _maxDepth) {
      return const Rejected(DeckRejection.depthExceeded);
    }
    if (movingRootScheduler != targetRootScheduler ||
        movingRootGeneration != targetRootGeneration) {
      return const Rejected(DeckRejection.subtreeSchedulerMismatch);
    }
    return const Ok(null);
  }
}
