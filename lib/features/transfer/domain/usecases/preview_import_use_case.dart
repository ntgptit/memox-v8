import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_sections_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

/// UC-TRANSFER-001 steps 4–5, A6, E2, E7, E8: what the import would do,
/// read once; the plan re-derives its preview as the user decides. Writes
/// nothing (BR-TRANSFER-006).
final class PreviewImportUseCase {
  const PreviewImportUseCase(this._cards);

  final CardTransferRepository _cards;

  Future<Outcome<ImportPlan, TransferRejection>> call({
    required String deckId,
    required SourceTable table,
    required ColumnMapping mapping,
    required bool hasHeaderRow,
  }) async {
    if (!mapping.isComplete) {
      return const Rejected(TransferRejection.mappingIncomplete);
    }
    final target = await _cards.importTarget(deckId);
    if (target == null) return const Rejected(TransferRejection.targetRejected);
    final sections = splitSections(
      table: table,
      mapping: mapping,
      hasHeaderRow: hasHeaderRow,
    );
    // Sections, or a flat source into a deck that cannot take cards, need
    // sub-decks of the target (BR-TRANSFER-001).
    final needsDecks = sections != null || !target.canHoldCards;
    if (needsDecks && target.isDeckOfCards) {
      return const Rejected(TransferRejection.sectionsNeedDeckContainer);
    }
    if (needsDecks && !target.hasRoomBelow) {
      return const Rejected(TransferRejection.depthExceeded);
    }
    final plan = ImportPlan(
      table: table,
      mapping: mapping,
      hasHeaderRow: hasHeaderRow,
      target: target,
      sections: sections,
    );
    // The default name does not change which rows are blank (E2).
    if (plan.preview(defaultDeckName: '', choices: const {}).isEmpty) {
      return const Rejected(TransferRejection.emptySource);
    }
    return Ok(plan);
  }
}
