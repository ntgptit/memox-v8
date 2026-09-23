import 'package:characters/characters.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

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

  /// The deepest level a deck may sit at; the root is level 1 (BR-DECK-001).
  static const maxDepth = 10;

  /// BR-DECK-020, in characters as a person sees them (grapheme clusters).
  static const maxNameLength = 200;

  bool get isRoot => parentId == null;

  /// BR-DECK-020: not blank after trim, at most [maxNameLength] characters.
  static Outcome<void, DeckRejection> checkName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const Rejected(DeckRejection.blankName);
    if (trimmed.characters.length > maxNameLength) {
      return const Rejected(DeckRejection.nameTooLong);
    }
    return const Ok(null);
  }

  /// A sub-deck goes into a deck that holds decks or nothing yet
  /// (BR-DECK-009), above the deepest level (BR-DECK-001).
  static Outcome<void, DeckRejection> checkCreateSubDeck({
    required int parentDepth,
    required DeckContentType parentContentType,
  }) {
    if (parentContentType == DeckContentType.card) {
      return const Rejected(DeckRejection.notADeckContainer);
    }
    if (parentDepth >= maxDepth) {
      return const Rejected(DeckRejection.depthExceeded);
    }
    return const Ok(null);
  }

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
  /// - [targetContentType]: a deck that holds cards takes no sub-deck
  ///   (BR-DECK-009).
  static Outcome<void, DeckRejection> checkMove({
    required String movingId,
    required String targetParentId,
    required List<String> targetAncestorIds,
    required int targetDepth,
    required int subtreeHeight,
    required DeckContentType targetContentType,
    required SchedulerType? movingRootScheduler,
    required int? movingRootGeneration,
    required SchedulerType? targetRootScheduler,
    required int? targetRootGeneration,
  }) {
    if (targetParentId == movingId || targetAncestorIds.contains(movingId)) {
      return const Rejected(DeckRejection.movingIntoOwnSubtree);
    }
    if (targetContentType == DeckContentType.card) {
      return const Rejected(DeckRejection.notADeckContainer);
    }
    if (targetDepth + subtreeHeight > maxDepth) {
      return const Rejected(DeckRejection.depthExceeded);
    }
    if (movingRootScheduler != targetRootScheduler ||
        movingRootGeneration != targetRootGeneration) {
      return const Rejected(DeckRejection.subtreeSchedulerMismatch);
    }
    return const Ok(null);
  }
}
