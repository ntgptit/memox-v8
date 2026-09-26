/// What an import did (UC-TRANSFER-001 step 8): the cards it added, and the
/// rows it left out.
final class ImportResult {
  const ImportResult({
    required this.added,
    required this.skippedDuplicates,
    required this.skippedInvalid,
    required this.ignoredBlank,
  });

  final int added;

  /// The duplicates it did not write; none when the person included them.
  final int skippedDuplicates;

  final int skippedInvalid;
  final int ignoredBlank;
}
