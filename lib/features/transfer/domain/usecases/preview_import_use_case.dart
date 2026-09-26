import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

/// UC-TRANSFER-001 steps 4–5: every row's status against the deck as it is
/// now. Writes nothing (BR-TRANSFER-006).
final class PreviewImportUseCase {
  const PreviewImportUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<ImportPreview, TransferRejection>> call({
    required String deckId,
    required SourceTable table,
    required ColumnMapping mapping,
    required bool hasHeaderRow,
  }) async {
    if (!mapping.isComplete) {
      return const Rejected(TransferRejection.mappingIncomplete);
    }
    final preview = buildImportPreview(
      table: table,
      mapping: mapping,
      hasHeaderRow: hasHeaderRow,
      existing: await _cards.foldedPairs(deckId),
    );
    if (preview.isEmpty) return const Rejected(TransferRejection.emptySource);
    return Ok(preview);
  }
}
