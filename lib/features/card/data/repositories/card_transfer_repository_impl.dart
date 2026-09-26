import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/data/datasources/card_list_dao.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';

/// An import writes every card inside one transaction, each as
/// [CardRepositoryImpl.insertCard] writes one; an export reads in one
/// transaction and writes nothing.
final class CardTransferRepositoryImpl implements CardTransferRepository {
  CardTransferRepositoryImpl(this._db, this._cards, {DateTime Function()? now})
    : _dao = CardDao(_db),
      _listDao = CardListDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final CardRepositoryImpl _cards;
  final CardDao _dao;
  final CardListDao _listDao;
  final DateTime Function() _now;

  @override
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) =>
      _mapped(() => _dao.foldedPairs(deckId));

  @override
  Future<Outcome<CardImportResult, CardRejection>> importCards({
    required String deckId,
    required List<CardDraft> drafts,
    required bool includeDuplicates,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      for (final draft in drafts) {
        if (draft.check() case Rejected(:final reason)) return Rejected(reason);
      }
      final deck = await _dao.deckRow(deckId);
      if (deck == null) return const Rejected(CardRejection.notFound);
      final contentType = DeckContentType.values.byName(deck.contentType);
      if (DeckEntity.checkCreateCard(parentContentType: contentType)
          case Rejected()) {
        return const Rejected(CardRejection.notACardContainer);
      }

      final taken = await _dao.foldedPairs(deckId);
      var written = 0;
      for (final draft in drafts) {
        final pair = (front: foldText(draft.front), back: foldText(draft.back));
        if (!includeDuplicates && taken.contains(pair)) continue;
        taken.add(pair);
        await _cards.insertCard(deckId, draft, at);
        written++;
      }
      if (written > 0 && contentType == DeckContentType.unset) {
        await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
      }
      return Ok(
        CardImportResult(
          written: written,
          skippedDuplicates: drafts.length - written,
        ),
      );
    });
  }

  @override
  Future<int> countCards(String deckId) =>
      _mapped(() => _dao.liveCount(deckId));

  @override
  Future<Outcome<CardExportSnapshot, CardRejection>> exportSnapshot({
    required String deckId,
    Set<String>? cardIds,
  }) => _mapped(
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

  /// One transaction; a throw rolls every row back and leaves as
  /// `mapDatabaseError`'s [Failure].
  Future<T> _write<T>(Future<T> Function() body) =>
      _mapped(() => _db.transaction(body));

  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
