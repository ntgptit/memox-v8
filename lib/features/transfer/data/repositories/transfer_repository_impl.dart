import 'dart:isolate';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/transfer/data/datasources/transfer_dao.dart';
import 'package:memox/features/transfer/data/mappers/delimited_text_mapper.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';

/// Import and export (transfer spec §7, §8). The commit of an import is one
/// transaction, which the card feature's batch create joins.
final class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl(this._db, this._cards, {DateTime Function()? now})
    : _dao = TransferDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final CardRepository _cards;
  final TransferDao _dao;
  final DateTime Function() _now;

  @override
  Future<Outcome<ImportDocument, TransferRejection>> readSource(
    ImportSource source,
  ) => Isolate.run(() => readDelimited(source));

  @override
  Future<ImportPreview> previewImport({
    required String deckId,
    required ImportSheet sheet,
    required ImportSettings settings,
  }) => _mapped(
    () async => ImportPreview.classify(
      sheet: sheet,
      settings: settings,
      deckKeys: await _dao.contentKeys(deckId),
    ),
  );

  @override
  Future<Outcome<ImportResult, TransferRejection>> importCards({
    required String deckId,
    required ImportSheet sheet,
    required ImportSettings settings,
    DateTime? now,
  }) => _mapped(
    () => _db.transaction(() async {
      final preview = ImportPreview.classify(
        sheet: sheet,
        settings: settings,
        deckKeys: await _dao.contentKeys(deckId),
      );
      if (preview.mapping.missing.isNotEmpty) {
        return const Rejected(TransferRejection.mappingIncomplete);
      }
      final written = await _cards.createCards(
        deckId: deckId,
        drafts: preview.toWrite,
        now: now ?? _now(),
      );
      return switch (written) {
        Ok(value: final ids) => Ok(
          ImportResult(
            added: ids.length,
            skippedDuplicates: settings.shouldIncludeDuplicates
                ? 0
                : preview.duplicateCount,
            skippedInvalid: preview.invalidCount,
            ignoredBlank: preview.blankCount,
          ),
        ),
        Rejected(reason: CardRejection.notFound) => const Rejected(
          TransferRejection.deckNotFound,
        ),
        Rejected(reason: CardRejection.notACardContainer) => const Rejected(
          TransferRejection.deckRejectsCards,
        ),
        // The classification checked every draft with the card's rules, so
        // any other refusal is a bug: throwing rolls the import back.
        Rejected(:final reason) => throw StateError(
          'the card rules refused a checked draft: $reason',
        ),
      };
    }),
  );

  /// [body], with an unexpected database error leaving as its [Failure].
  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
