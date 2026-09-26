import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';

/// UC-TRANSFER-001 steps 2-3: a picked file or pasted text read in memory;
/// nothing is written (BR-TRANSFER-006).
final class ReadImportSourceUseCase {
  const ReadImportSourceUseCase(this._transfer);

  final TransferRepository _transfer;

  Future<Outcome<ImportDocument, TransferRejection>> call(
    ImportSource source,
  ) => _transfer.readSource(source);
}
