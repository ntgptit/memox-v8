/// What one import wrote (UC-TRANSFER-001 step 8).
final class CardImportResult {
  const CardImportResult({required this.written, required this.skippedIndexes});

  final int written;

  /// The places, in the drafts handed in, of those the duplicate policy
  /// dropped inside the commit (BR-TRANSFER-003), in order.
  final List<int> skippedIndexes;

  int get skippedDuplicates => skippedIndexes.length;
}
