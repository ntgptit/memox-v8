import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';

/// Row access for transfer: the keys of a deck's cards (transfer spec
/// §6.2) and the three reads of an export's snapshot (§8.1). It runs
/// inside the caller's transaction.
final class TransferDao {
  TransferDao(this._db);

  final AppDatabase _db;

  /// The folded front and back of every active card of [deckId]
  /// (BR-TRANSFER-003).
  Future<Set<ContentKey>> contentKeys(String deckId) async {
    final card = _db.card;
    final rows =
        await (_db.selectOnly(card)
              ..addColumns([card.frontFolded, card.backFolded])
              ..where(card.deckId.equals(deckId) & card.deleteBatchId.isNull()))
            .get();
    return {
      for (final row in rows)
        (row.read(card.frontFolded)!, row.read(card.backFolded)!),
    };
  }

  /// The name of [deckId], unless it is gone or in the Trash.
  Future<String?> activeDeckName(String deckId) async {
    final deck =
        await (_db.select(_db.deck)..where(
              (deck) => deck.id.equals(deckId) & deck.deleteBatchId.isNull(),
            ))
            .getSingleOrNull();
    return deck?.name;
  }

  /// The active cards of [deckId] itself, oldest first, then by id
  /// (BR-TRANSFER-007, BR-TRANSFER-010).
  Future<List<CardRow>> activeCards(String deckId) =>
      (_db.select(_db.card)
            ..where(
              (card) =>
                  card.deckId.equals(deckId) & card.deleteBatchId.isNull(),
            )
            ..orderBy([
              (card) => OrderingTerm(expression: card.createdAt),
              (card) => OrderingTerm(expression: card.id),
            ]))
          .get();

  /// The tag names of the active cards of [deckId], by card, in one
  /// statement rather than one a card, each card's by folded name, then id
  /// (BR-TRANSFER-010).
  Future<Map<String, List<String>>> tagNames(String deckId) async {
    final rows = await _db
        .customSelect(
          'SELECT ct.card_id, t.name FROM card_tags ct'
          ' JOIN tags t ON t.id = ct.tag_id'
          ' JOIN card c ON c.id = ct.card_id'
          ' WHERE c.deck_id = ? AND c.delete_batch_id IS NULL'
          ' AND t.owner_id IS NULL'
          ' ORDER BY ct.card_id, t.name_folded, t.id',
          variables: [Variable<String>(deckId)],
          readsFrom: {_db.cardTags, _db.tags, _db.card},
        )
        .get();
    final names = <String, List<String>>{};
    for (final row in rows) {
      names
          .putIfAbsent(row.read<String>('card_id'), () => [])
          .add(row.read<String>('name'));
    }
    return names;
  }
}
