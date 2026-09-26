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
