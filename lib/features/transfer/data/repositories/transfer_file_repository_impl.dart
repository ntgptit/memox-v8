import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/data/datasources/delimited_text_data_source.dart';
import 'package:memox/features/transfer/data/datasources/xlsx_data_source.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';

/// Runs [callback] on [message]: off the UI isolate by default.
typedef TransferRunner = Future<R> Function<Q, R>(
  FutureOr<R> Function(Q) callback,
  Q message,
);

/// Reading and writing run off the UI isolate through [compute], which runs
/// them inline on the web build E2E uses (spec D7, ADR-001). A widget test,
/// whose clock is fake, passes a runner that calls inline.
final class TransferFileRepositoryImpl implements TransferFileRepository {
  const TransferFileRepositoryImpl({this._run = _compute});

  final TransferRunner _run;

  @override
  Future<Outcome<SourceTable, TransferRejection>> read(
    TransferSource source, {
    int? sheetIndex,
  }) => _run(_read, (source, sheetIndex));

  @override
  Future<Outcome<Uint8List, TransferRejection>> write(
    List<List<String>> rows,
    TransferFormat format,
  ) => _run(_write, (rows, format));
}

Future<R> _compute<Q, R>(FutureOr<R> Function(Q) callback, Q message) =>
    compute(callback, message);

const _delimited = DelimitedTextDataSource();
const _xlsx = XlsxDataSource();

Outcome<SourceTable, TransferRejection> _read((TransferSource, int?) request) {
  final (source, sheetIndex) = request;
  final table = switch (source) {
    PastedSource(:final text) => _pasted(text),
    FileSource(:final bytes, format: TransferFormat.xlsx) => _workbook(
      bytes,
      sheetIndex,
    ),
    FileSource(:final bytes, :final format) => _delimitedFile(bytes, format),
  };
  if (table case Ok(:final value) when value.isBlank) {
    return const Rejected(TransferRejection.emptySource);
  }
  return table;
}

Outcome<SourceTable, TransferRejection> _pasted(String text) => Ok(
  SourceTable(rows: _delimited.parse(text, _delimited.delimiterOfPasted(text))),
);

Outcome<SourceTable, TransferRejection> _delimitedFile(
  Uint8List bytes,
  TransferFormat format,
) {
  final String text;
  try {
    text = _delimited.decodeUtf8(bytes);
  } on FormatException {
    return const Rejected(TransferRejection.badEncoding);
  }
  final delimiter = format == TransferFormat.tsv
      ? DelimitedTextDataSource.tab
      : DelimitedTextDataSource.comma;
  return Ok(SourceTable(rows: _delimited.parse(text, delimiter)));
}

Outcome<SourceTable, TransferRejection> _workbook(
  Uint8List bytes,
  int? sheetIndex,
) {
  try {
    final workbook = _xlsx.read(bytes, sheetIndex: sheetIndex);
    return Ok(
      SourceTable(
        rows: workbook.rows,
        sheetNames: workbook.sheetNames,
        sheetIndex: workbook.sheetIndex,
      ),
    );
  } on Object {
    // Whatever the package throws for a damaged or protected workbook, the
    // user sees one typed reason and nothing of the file (BR-TRANSFER-006).
    return const Rejected(TransferRejection.unreadableFile);
  }
}

Outcome<Uint8List, TransferRejection> _write(
  (List<List<String>>, TransferFormat) request,
) {
  final (rows, format) = request;
  try {
    return Ok(switch (format) {
      TransferFormat.csv => _delimited.encode(
        rows,
        DelimitedTextDataSource.comma,
      ),
      TransferFormat.tsv => _delimited.encode(
        rows,
        DelimitedTextDataSource.tab,
      ),
      TransferFormat.xlsx => _xlsx.write(rows),
    });
  } on Object {
    return const Rejected(TransferRejection.encodeFailed);
  }
}
