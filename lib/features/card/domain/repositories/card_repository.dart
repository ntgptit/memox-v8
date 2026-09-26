import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';
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

  /// Their schedule rows, logs and tag links go with them; a deck left with
  /// no card is unset again (BR-DECK-015).
  Future<Outcome<void, CardRejection>> deleteCards({
    required Set<String> cardIds,
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

  /// BR-TRANSFER-003: the folded faces of the live cards of [deckId], the
  /// set an import preview marks duplicates against.
  Future<Set<CardFoldedPair>> foldedPairs(String deckId);

  /// UC-TRANSFER-001 step 7, in one transaction: the deck is checked again
  /// (BR-TRANSFER-001), the duplicate policy is applied again against the
  /// deck as it is now and within [drafts] (BR-TRANSFER-003), and each draft
  /// kept is written as [createCard] writes one (BR-TRANSFER-004). The deck
  /// becomes a deck of cards only when a card was written (BR-TRANSFER-005).
  /// A draft the card rules refuse refuses the batch, and nothing is
  /// written.
  Future<Outcome<CardImportResult, CardRejection>> importCards({
    required String deckId,
    required List<CardDraft> drafts,
    required bool includeDuplicates,
    DateTime? now,
  });

  /// UC-TRANSFER-002 step 4: the deck's name and its live cards, or those of
  /// [cardIds], in one read that writes nothing (BR-TRANSFER-010,
  /// BR-TRANSFER-011). A missing deck, or an id that is gone or in another
  /// deck, is `notFound` for the whole request (BR-TRANSFER-007). An empty
  /// scope is an empty snapshot; the caller refuses it.
  Future<Outcome<CardExportSnapshot, CardRejection>> exportSnapshot({
    required String deckId,
    Set<String>? cardIds,
  });
}
