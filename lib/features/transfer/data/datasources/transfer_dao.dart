import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';

/// Row access for transfer: the keys of a deck's cards (transfer spec
/// §6.2). It runs inside the caller's transaction.
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
}
