import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';

/// UC-TRANSFER-001 steps 6-8: the import, all or nothing (BR-TRANSFER-004).
final class ImportCardsUseCase {
  const ImportCardsUseCase(this._transfer);

  final TransferRepository _transfer;

  Future<Outcome<ImportResult, TransferRejection>> call({
    required String deckId,
    required ImportSheet sheet,
    required ImportSettings settings,
  }) => _transfer.importCards(deckId: deckId, sheet: sheet, settings: settings);
}
