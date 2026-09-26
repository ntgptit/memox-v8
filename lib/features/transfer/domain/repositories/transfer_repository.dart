import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';

/// The one implementation is `TransferRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and
/// tests substitute a fake.
abstract interface class TransferRepository {
  /// UC-TRANSFER-001 steps 2-3: [source] read in memory, off the calling
  /// isolate, as a document (transfer spec §5). Refuses a file that is
  /// neither a .csv nor a .tsv (unsupportedFormat), one that is not UTF-8
  /// (notUtf8), and a source that cannot be read (unreadable) (E1,
  /// BR-TRANSFER-006).
  Future<Outcome<ImportDocument, TransferRejection>> readSource(
    ImportSource source,
  );

  /// UC-TRANSFER-001 step 5: the data rows of [sheet], classified against
  /// the active cards of [deckId] as they are now (transfer spec §6.2).
  /// Writes nothing.
  Future<ImportPreview> previewImport({
    required String deckId,
    required ImportSheet sheet,
    required ImportSettings settings,
  });

  /// UC-TRANSFER-001 steps 6-7, in one transaction: classifies [sheet] again
  /// on the deck as it is (BR-TRANSFER-003) and writes the rows to write as
  /// new cards (BR-TRANSFER-004, BR-TRANSFER-005). Refuses, writing nothing,
  /// while front or back has no column (mappingIncomplete), and when the
  /// deck is gone (deckNotFound) or takes no card (deckRejectsCards) (E4).
  /// A failure rolls everything back and leaves as a database `Failure`
  /// (E5).
  Future<Outcome<ImportResult, TransferRejection>> importCards({
    required String deckId,
    required ImportSheet sheet,
    required ImportSettings settings,
    DateTime? now,
  });
}
