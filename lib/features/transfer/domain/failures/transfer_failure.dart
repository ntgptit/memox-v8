/// Why Card Transfer refuses a step (ADR-011 D6). A database failure is not
/// a reason here: it leaves as the thrown `Failure`, as every other write
/// and read does.
enum TransferRejection {
  /// UC-TRANSFER-001 E1: a file that is not CSV, TSV or XLSX, or that cannot
  /// be read (damaged, protected).
  unreadableFile,

  /// BR-TRANSFER-006: text that is not UTF-8 or UTF-8 with a BOM.
  badEncoding,

  /// UC-TRANSFER-001 E2: no row holds anything.
  emptySource,

  /// BR-TRANSFER-002: `front` or `back` is not mapped, or two columns map to
  /// one field.
  mappingIncomplete,

  /// UC-TRANSFER-001 E3: under the chosen duplicate policy, no row would be
  /// written.
  nothingToImport,

  /// BR-TRANSFER-001, UC-TRANSFER-001 E4: the deck is gone, is a root, or
  /// holds sub-decks.
  targetRejected,

  /// BR-TRANSFER-001, UC-TRANSFER-001 E7: a sectioned source from a deck
  /// of cards.
  sectionsNeedDeckContainer,

  /// BR-DECK-001, UC-TRANSFER-001 E8: the target is at level 10.
  depthExceeded,

  /// BR-TRANSFER-001, UC-TRANSFER-001 E9: a deck chosen for "Add to
  /// existing" changed before the commit.
  sectionTargetChanged,

  /// Spec 2026-10-08 U6: a clash is undecided or the default name is
  /// refused.
  sectionChoiceMissing,

  /// BR-TRANSFER-007, UC-TRANSFER-002 E5: nothing to export.
  emptyScope,

  /// BR-TRANSFER-007, UC-TRANSFER-002 E6: a chosen card is gone or has moved.
  staleSelection,

  /// UC-TRANSFER-002 E4: the file could not be written.
  encodeFailed,

  /// UC-TRANSFER-002 E1: this device has no share sheet.
  shareUnavailable,

  /// UC-TRANSFER-002 E2: the platform failed while sharing.
  shareFailed,
}
