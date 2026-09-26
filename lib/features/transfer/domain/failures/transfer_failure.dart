/// Why the transfer feature refuses a request (ADR-011 D6).
enum TransferRejection {
  /// UC-TRANSFER-001 E1: the file is neither a .csv nor a .tsv.
  unsupportedFormat,

  /// UC-TRANSFER-001 E1, BR-TRANSFER-006: the file is not UTF-8.
  notUtf8,

  /// UC-TRANSFER-001 E1: the source cannot be read, like a quoted field
  /// that never closes.
  unreadable,

  /// BR-TRANSFER-002: no column feeds the front or the back.
  mappingIncomplete,

  /// UC-TRANSFER-001 E4: the target deck is gone or in the Trash.
  deckNotFound,

  /// UC-TRANSFER-001 E4, BR-TRANSFER-001: the target deck is a root or
  /// holds sub-decks.
  deckRejectsCards,

  /// UC-TRANSFER-002 E5, BR-TRANSFER-007: the deck has no card, or the
  /// selection is empty.
  emptyScope,

  /// UC-TRANSFER-002 E6, BR-TRANSFER-007: a selected card is gone, in the
  /// Trash, or in another deck.
  staleSelection,
}
