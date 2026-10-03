import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';

/// The one implementation is `CardRepositoryImpl` (data layer). The contract
/// exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
///
/// A batch takes a set of card ids and works in one transaction. The ids that
/// still exist are written and the ones already gone are skipped, answered as
/// a [BulkOutcome]; when none exists the batch is `notFound`. A card the
/// rules refuse (a move target that does not take it) refuses the whole
/// batch, and nothing is written (BR-CARD-011). An empty set writes nothing
/// and answers `Ok`.
abstract interface class CardRepository {
  /// UC-CARD-001: the card, its schedule row (BR-CARD-004) and its tags, and
  /// the deck becomes a deck of cards when it held nothing (BR-DECK-008).
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
    DateTime? now,
  });

  /// UC-CARD-001 A1: new content, flag and tags; the schedule row and the
  /// review log stay as they are (BR-CARD-005). When [expectedUpdatedAt] is
  /// given and the card carries another `updated_at`, nothing is written and
  /// the answer is `changedElsewhere` (SP2a 2.18); null skips the check.
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? expectedUpdatedAt,
    DateTime? now,
  });

  /// UC-CARD-001 A2: each card goes to the Trash as a batch of its own, all
  /// at one time, and the batch ids come back in `BulkOutcome.batchIds`, in
  /// the order of the cards done (BR-TRASH-001). A deck left with no active
  /// card is unset again (BR-TRASH-005); the sessions they touch end
  /// (BR-TRASH-004).
  Future<Outcome<BulkOutcome, CardRejection>> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  });

  /// UC-TRASH-001 steps 5-7: the cards of [batchIds] come back into
  /// [deckId], a sub-deck of their root that holds cards or nothing, all or
  /// none; `deck_id` and `updated_at` change as in a move (BR-TRASH-006,
  /// BR-TRASH-007).
  Future<Outcome<void, CardRejection>> restoreCards({
    required Set<String> batchIds,
    required String deckId,
    DateTime? now,
  });

  /// BR-TRASH-008: the cards of [batchIds], the batches one delete wrote, go
  /// back each into its own deck with its `updated_at` kept; all or none. It
  /// is refused, typed, when any of those decks no longer takes its card, and
  /// `notFound` when a batch is gone (SP2a 2.20).
  Future<Outcome<void, CardRejection>> undoCardDeletion({
    required Set<String> batchIds,
    DateTime? now,
  });

  /// BR-CARD-010: only `deck_id` and `updated_at` change.
  Future<Outcome<BulkOutcome, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
    DateTime? now,
  });

  /// An explicit value for every card, never a toggle (BR-CARD-011).
  Future<Outcome<BulkOutcome, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  });

  /// UC-CARD-001: the first [windowSize] cards of [deckId] that [query] lets
  /// through, whether more follow, and the count of every filter under the
  /// same search and tags (IT-ORG-005, BR-TAG-004). Due is due at [now].
  /// Each item carries its tags and due label, and the view counts the
  /// deck's display states whatever the search, filter and tags. Emits again
  /// on every change of a card, a schedule row, a tag or a card's tags.
  Stream<CardListView> watchCardList({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
    required DateTime now,
  });

  /// BR-CARD-012: the ids of every card [query] lets through.
  Future<Set<String>> cardIdsMatching({
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  });

  /// BR-CARD-014: the card with its tags and schedule, again whenever one of
  /// them changes; null once it is gone or in the Trash (BR-CARD-019).
  /// Reading writes nothing (BR-CARD-013).
  Stream<CardDetail?> watchDetail(String cardId);

  /// BR-CARD-015: the page of the card's history after [after], the newest
  /// page when it is null; null when the card is not active.
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  });

  /// BR-CARD-010: where the cards of [sourceDeckId] may move, in tree order.
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId);

  /// UC-TRASH-001 step 5: where the cards of [batchIds] may go back, again
  /// on every change of the decks, the cards or the batches: the decks of
  /// their one root that hold cards or nothing (BR-TRASH-006, E1, E2).
  Stream<List<CardMoveTarget>> watchRestoreTargets(Set<String> batchIds);
}
