/// What one import wrote (UC-TRANSFER-001 step 8).
final class CardImportResult {
  const CardImportResult({
    required this.written,
    required this.skippedDuplicates,
  });

  final int written;

  /// Drafts the duplicate policy dropped inside the commit (BR-TRANSFER-003).
  final int skippedDuplicates;
}
