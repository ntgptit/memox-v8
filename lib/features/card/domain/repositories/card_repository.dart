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
/// A batch takes a set of card ids and is all or nothing in one transaction:
/// one card the rules refuse refuses the batch, and nothing is written
/// (BR-CARD-011). An empty set writes nothing and answers `Ok`.
abstract interface class CardRepository {
  /// UC-CARD-001: the card, its schedule row (BR-CARD-004) and its tags, and
  /// the deck becomes a deck of cards when it held nothing (BR-DECK-008).
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
    DateTime? now,
  });

  /// UC-CARD-001 A1: new content, flag and tags; the schedule row and the
  /// review log stay as they are (BR-CARD-005).
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? now,
  });

  /// UC-CARD-001 A2: each card goes to the Trash as a batch of its own, all
  /// at one time, and the batch ids come back in the order of [cardIds]
  /// (BR-TRASH-001). A deck left with no active card is unset again
  /// (BR-TRASH-005); the sessions they touch end (BR-TRASH-004).
  Future<Outcome<List<String>, CardRejection>> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  });

  /// BR-CARD-010: only `deck_id` and `updated_at` change.
  Future<Outcome<void, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
    DateTime? now,
  });

  /// An explicit value for every card, never a toggle (BR-CARD-011).
  Future<Outcome<void, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  });

  /// UC-CARD-001: the first [windowSize] cards of [deckId] that [query] lets
  /// through, whether more follow, and the count of every filter under the
  /// same search (IT-ORG-005). Due is due at [now]. Each item carries its
  /// tags and due label, and the view counts the deck's display states
  /// whatever the search and filter. Emits again on every change of a card,
  /// a schedule row or a card's tags.
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
}
