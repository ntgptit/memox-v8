import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';

// What the transfer file tests share: the repository and its three ways of
// reading a source.

const transferFiles = TransferFileRepositoryImpl();

Uint8List utf8Bytes(String text) => Uint8List.fromList(utf8.encode(text));

Future<SourceTable> tableOf(TransferSource source, {int? sheetIndex}) async {
  final result = await transferFiles.read(source, sheetIndex: sheetIndex);
  return (result as Ok<SourceTable, TransferRejection>).value;
}

Future<TransferRejection> refusalOf(TransferSource source) async {
  final result = await transferFiles.read(source);
  return (result as Rejected<SourceTable, TransferRejection>).reason;
}
