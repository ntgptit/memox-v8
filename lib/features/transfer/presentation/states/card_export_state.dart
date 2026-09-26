import 'package:flutter/foundation.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

/// What one export sheet exports, fixed by its entry point
/// (UC-TRANSFER-002 step 1, BR-TRANSFER-007): the whole deck, counted before
/// the sheet opens, or the cards selected on the card list (A1).
@immutable
final class CardExportScope {
  const CardExportScope.deck({
    required this.deckId,
    required String this.deckName,
    required this.cardCount,
  }) : cardIds = null;

  CardExportScope.selection({required this.deckId, required Set<String> ids})
    : cardIds = Set.unmodifiable(ids),
      deckName = null,
      cardCount = ids.length;

  final String deckId;

  /// The deck's name for the whole-deck subtitle; null for a selection.
  final String? deckName;
  final int cardCount;

  /// The selected cards; null for the whole deck.
  final Set<String>? cardIds;

  bool get isSelection => cardIds != null;

  @override
  bool operator ==(Object other) =>
      other is CardExportScope &&
      other.deckId == deckId &&
      other.deckName == deckName &&
      other.cardCount == cardCount &&
      setEquals(other.cardIds, cardIds);

  @override
  int get hashCode => Object.hash(
    deckId,
    deckName,
    cardCount,
    cardIds == null ? null : Object.hashAllUnordered(cardIds!),
  );
}

/// Why the sheet cannot export as it stands (kit 12's banners).
enum CardExportProblem {
  /// E3, E4: the cards could not be read or the file could not be written.
  prepareFailed,

  /// E2: the platform failed while sharing.
  shareFailed,

  /// E1: this device has no share sheet.
  noShareTarget,

  /// E6: a selected card is gone or has moved.
  staleSelection,

  /// E5: the scope holds no card.
  nothingToExport;

  /// A problem Try again cannot fix: the sheet offers Close only.
  bool get isFinal => switch (this) {
    prepareFailed || shareFailed => false,
    noShareTarget || staleSelection || nothingToExport => true,
  };
}

/// The export sheet (kit 12): the format, whether a file is being
/// prepared, the problem if any, and whether the file was handed over.
@immutable
final class CardExportState {
  const CardExportState({
    this.format = TransferFormat.csv,
    this.isPreparing = false,
    this.problem,
    this.isHandedOver = false,
  });

  /// CSV by default (UC-TRANSFER-002 step 2).
  final TransferFormat format;

  /// Building or sharing; the primary action is locked (A4).
  final bool isPreparing;
  final CardExportProblem? problem;

  /// The share sheet took the file (step 7); the sheet closes.
  final bool isHandedOver;

  bool get canExport =>
      !isPreparing && !isHandedOver && !(problem?.isFinal ?? false);
}
