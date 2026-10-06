import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/mapped_transaction.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/data/datasources/card_list_dao.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';

/// An import keeps the duplicate policy and writes the drafts it keeps
/// through [CardRepository.insertCards], inside one transaction: the deck's
/// rules and its content type are the card and deck features' to hold. An
/// export reads in one transaction and writes nothing.
final class CardTransferRepositoryImpl implements CardTransferRepository {
  CardTransferRepositoryImpl(this._db, this._cards, {DateTime Function()? now})
    : _dao = CardDao(_db),
      _listDao = CardListDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final CardRepository _cards;
  final CardDao _dao;
  final CardListDao _listDao;
  final DateTime Function() _now;

  @override
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) =>
      guardDatabase(() => _dao.foldedPairs(deckId));

  @override
  Future<Outcome<CardImportResult, CardRejection>> importCards({
    required String deckId,
    required List<CardDraft> drafts,
    required bool includeDuplicates,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      // Every draft, the skipped ones too: a draft the rules refuse refuses
      // the batch (BR-TRANSFER-004).
      for (final draft in drafts) {
        if (draft.check() case Rejected(:final reason)) return Rejected(reason);
      }
      final taken = await _dao.foldedPairs(deckId);
      final kept = <CardDraft>[];
      final skipped = <int>[];
      for (final (index, draft) in drafts.indexed) {
        final pair = (front: foldText(draft.front), back: foldText(draft.back));
        if (!includeDuplicates && taken.contains(pair)) {
          skipped.add(index);
          continue;
        }
        taken.add(pair);
        kept.add(draft);
      }
      final written = await _cards.insertCards(
        deckId: deckId,
        drafts: kept,
        now: at,
      );
      return switch (written) {
        Rejected(:final reason) => Rejected(reason),
        Ok(:final value) => Ok(
          CardImportResult(written: value.length, skippedIndexes: skipped),
        ),
      };
    });
  }

  @override
  Future<int> countCards(String deckId) =>
      guardDatabase(() => _dao.liveCount(deckId));

  @override
  Future<Outcome<CardExportSnapshot, CardRejection>> exportSnapshot({
    required String deckId,
    Set<String>? cardIds,
  }) => guardDatabase(
    () => _db.transaction(() async {
      final deck = await _dao.deckRow(deckId);
      if (deck == null) return const Rejected(CardRejection.notFound);
      final rows = await _dao.exportRows(deckId, cardIds);
      if (cardIds != null && rows.length != cardIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      final tags = await _listDao.tagsOf([for (final row in rows) row.id]);
      return Ok(
        CardExportSnapshot(
          deckName: deck.name,
          rows: [
            for (final row in rows)
              CardExportRow(
                front: row.front,
                back: row.back,
                example: row.example,
                hint: row.hint,
                pronunciation: row.pronunciation,
                tagNames: [
                  for (final tag in tags[row.id] ?? const <Tag>[]) tag.name,
                ],
              ),
          ],
        ),
      );
    }),
  );
}
