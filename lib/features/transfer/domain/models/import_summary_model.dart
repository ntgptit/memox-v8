import 'package:memox/features/transfer/domain/models/import_preview_model.dart';

/// Which result screen an import ends on (UC-TRANSFER-001 step 8; kit
/// screen 11: success, partial, none).
enum ImportSummaryKind { success, partial, none }

/// What an import did (UC-TRANSFER-001 step 8): the cards written, the blank
/// rows ignored, and every row skipped, with why.
final class ImportSummary {
  const ImportSummary({
    required this.written,
    required this.blank,
    required this.skipped,
  });

  final int written;
  final int blank;

  /// The rows not written, in source order: the invalid ones, the duplicates
  /// the preview found when they were not included, and those the commit's
  /// own re-check found, marked as already in the deck (BR-TRANSFER-003;
  /// critique 2026-10-02, F4). A blank row is ignored, not skipped
  /// (BR-TRANSFER-002).
  final List<ImportRow> skipped;

  int get duplicatesSkipped => skipped.where((row) => row.isDuplicate).length;

  int get invalid =>
      skipped.where((row) => row.kind == ImportRowKind.invalid).length;

  /// `none`: the commit found nothing left to write (spec §8.1 ruling 1).
  /// A blank row is ignored, not skipped, so it alone keeps `success`.
  ImportSummaryKind get kind {
    if (written == 0) return ImportSummaryKind.none;
    if (skipped.isNotEmpty) return ImportSummaryKind.partial;
    return ImportSummaryKind.success;
  }
}
