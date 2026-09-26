import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';

/// UC-TRANSFER-001 steps 4-5: every data row of a sheet with its status,
/// against the deck as it is now; nothing is written.
final class PreviewImportUseCase {
  const PreviewImportUseCase(this._transfer);

  final TransferRepository _transfer;

  Future<ImportPreview> call({
    required String deckId,
    required ImportSheet sheet,
    ImportSettings settings = const ImportSettings(),
  }) =>
      _transfer.previewImport(deckId: deckId, sheet: sheet, settings: settings);
}
