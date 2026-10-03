/// What one import wrote (UC-TRANSFER-001 step 8).
final class CardImportResult {
  const CardImportResult({
    required this.written,
    required this.skippedIndexes,
    required this.writtenIds,
  });

  final int written;

  /// The places, in the drafts handed in, of those the duplicate policy
  /// dropped inside the commit (BR-TRANSFER-003), in order.
  final List<int> skippedIndexes;

  /// The ids of the cards written, in the order of the drafts kept; an Undo
  /// import names them (SP2a 2.25).
  final List<String> writtenIds;
}
