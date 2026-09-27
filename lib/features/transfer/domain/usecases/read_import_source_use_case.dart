import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';

/// UC-TRANSFER-001 step 3, A2, E1, E2: the source read into rows, in
/// memory, writing nothing (BR-TRANSFER-006).
final class ReadImportSourceUseCase {
  const ReadImportSourceUseCase(this._files);

  final TransferFileRepository _files;

  Future<Outcome<SourceTable, TransferRejection>> call(
    TransferSource source, {
    int? sheetIndex,
  }) => _files.read(source, sheetIndex: sheetIndex);
}
