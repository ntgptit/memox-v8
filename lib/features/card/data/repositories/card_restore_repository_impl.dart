import 'package:memox/core/database/app_database.dart' hide CardDraft;
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';

/// The reads and writes of bringing trashed cards back into a deck, which
/// `CardRepositoryImpl` runs inside its own transaction.
final class CardRestoreRepositoryImpl {
  const CardRestoreRepositoryImpl(this._dao);

  final CardDao _dao;

  /// Why [cards], by batch, cannot go back into [deckId], or null when it
  /// takes them (BR-TRASH-006). Reads only.
  Future<CardRejection?> refusal(
    String deckId,
    Map<String, CardRow> cards,
  ) async {
    final target = await _dao.deckRow(deckId);
    if (target == null) {
      return await _dao.isDeckInTrash(deckId)
          ? CardRejection.targetInTrash
          : CardRejection.targetNotFound;
    }
    final rule = CardEntity.checkTarget(
      targetRootId: target.rootId,
      targetIsRoot: target.parentId == null,
      targetContentType: DeckContentType.values.byName(target.contentType),
      sourceRootIds: await _dao.rootIdsOf({
        for (final card in cards.values) card.deckId,
      }),
    );
    if (rule case Rejected(:final reason)) return reason;
    return null;
  }

  /// The writes of a restore that [refusal] accepted. An unset deck becomes
  /// a deck of cards (BR-DECK-008).
  Future<void> write(
    String deckId,
    Map<String, CardRow> cards, {
    DateTime? updatedAt,
    required DateTime at,
  }) async {
    for (final MapEntry(key: batchId, value: card) in cards.entries) {
      await _dao.restoreFromBatch(
        batchId,
        card.id,
        deckId: deckId,
        updatedAt: updatedAt,
      );
    }
    final target = (await _dao.deckRow(deckId))!;
    if (target.contentType == DeckContentType.unset.name) {
      await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
    }
  }
}
