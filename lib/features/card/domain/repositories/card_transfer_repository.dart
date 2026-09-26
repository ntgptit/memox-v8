import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';

/// The card feature's half of Card Transfer (UC-TRANSFER-001,
/// UC-TRANSFER-002): the duplicate key, the batch write of an import, and
/// the reads of an export. The card feature keeps every read and write of
/// cards; the transfer feature reaches them only through this contract.
abstract interface class CardTransferRepository {
  /// BR-TRANSFER-003: the folded faces of the live cards of [deckId], the
  /// set an import preview marks duplicates against.
  Future<Set<CardFoldedPair>> foldedPairs(String deckId);

  /// UC-TRANSFER-001 step 7, in one transaction: the deck is checked again
  /// (BR-TRANSFER-001), the duplicate policy is applied again against the
  /// deck as it is now and within [drafts] (BR-TRANSFER-003), and each draft
  /// kept is written as `CardRepository.createCard` writes one (BR-TRANSFER-004). The deck
  /// becomes a deck of cards only when a card was written (BR-TRANSFER-005).
  /// A draft the card rules refuse refuses the batch, and nothing is
  /// written.
  Future<Outcome<CardImportResult, CardRejection>> importCards({
    required String deckId,
    required List<CardDraft> drafts,
    required bool includeDuplicates,
    DateTime? now,
  });

  /// UC-TRANSFER-002 step 1: how many live cards [deckId] holds, the count a
  /// whole-deck export names before its sheet opens; 0 for a deck that is
  /// gone.
  Future<int> countCards(String deckId);

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
