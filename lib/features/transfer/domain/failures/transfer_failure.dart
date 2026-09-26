/// Why the transfer feature refuses a request (ADR-011 D6).
enum TransferRejection {
  /// BR-TRANSFER-002: no column feeds the front or the back.
  mappingIncomplete,

  /// UC-TRANSFER-001 E4: the target deck is gone or in the Trash.
  deckNotFound,

  /// UC-TRANSFER-001 E4, BR-TRANSFER-001: the target deck is a root or
  /// holds sub-decks.
  deckRejectsCards,
}
