import 'dart:async';
import 'dart:typed_data';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';

/// The real encoders, run inline; each write waits for [hold] while it is
/// set.
final class HeldTransferFiles implements TransferFileRepository {
  final _inner = TransferFileRepositoryImpl(
    run: <Q, R>(callback, message) async => callback(message),
  );
  Completer<void>? hold;

  @override
  Future<Outcome<Uint8List, TransferRejection>> write(
    List<List<String>> rows,
    TransferFormat format,
  ) async {
    await hold?.future;
    return _inner.write(rows, format);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
