/// Which result screen an import ends on (UC-TRANSFER-001 step 8; kit
/// screen 11: success, partial, none).
enum ImportSummaryKind { success, partial, none }

/// What one commit did, counted for the result screen.
final class ImportSummary {
  const ImportSummary({
    required this.written,
    required this.duplicatesSkipped,
    required this.invalid,
    required this.blank,
  });

  final int written;

  /// Skipped by the preview's policy and by the commit's own re-check
  /// (BR-TRANSFER-003).
  final int duplicatesSkipped;
  final int invalid;
  final int blank;

  /// `none`: the commit found nothing left to write (spec §8.1 ruling 1).
  /// A blank row is ignored, not skipped, so it alone keeps `success`.
  ImportSummaryKind get kind {
    if (written == 0) return ImportSummaryKind.none;
    if (duplicatesSkipped + invalid > 0) return ImportSummaryKind.partial;
    return ImportSummaryKind.success;
  }
}
