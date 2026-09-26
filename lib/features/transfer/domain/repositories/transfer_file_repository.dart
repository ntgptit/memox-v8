import 'dart:typed_data';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';

/// Reads a source into rows of text and writes rows into a file. The one
/// implementation is `TransferFileRepositoryImpl` (data layer); the contract
/// exists for ADR-010's reason: domain stays free of the codec packages, and
/// tests substitute a fake. Nothing here logs content (BR-TRANSFER-006).
abstract interface class TransferFileRepository {
  /// UC-TRANSFER-001 steps 3–4, E1: [sheetIndex] picks a sheet of an XLSX;
  /// null picks the first sheet that holds anything (A2).
  Future<Outcome<SourceTable, TransferRejection>> read(
    TransferSource source, {
    int? sheetIndex,
  });

  /// UC-TRANSFER-002 step 5 (BR-TRANSFER-012): [rows] as a file of [format].
  Future<Outcome<Uint8List, TransferRejection>> write(
    List<List<String>> rows,
    TransferFormat format,
  );
}
