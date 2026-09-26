import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';

/// Row access for `card`, plus the reads and writes of the owning `deck` row
/// that card writes need. It returns Drift rows, never domain entities, and
/// runs inside the caller's transaction. A card or deck in the Trash is out
/// of reach of every write (spec §8).
final class CardDao {
  CardDao(this._db);

  final AppDatabase _db;

  Future<CardRow?> findRow(String id) =>
      (_db.select(_db.card)
            ..where((card) => card.id.equals(id) & card.deleteBatchId.isNull()))
          .getSingleOrNull();

  /// The active cards among [ids].
  Future<List<CardRow>> liveRows(Set<String> ids) => (_db.select(
    _db.card,
  )..where((card) => card.id.isIn(ids) & card.deleteBatchId.isNull())).get();

  Future<Deck?> deckRow(String id) =>
      (_db.select(_db.deck)
            ..where((deck) => deck.id.equals(id) & deck.deleteBatchId.isNull()))
          .getSingleOrNull();

  /// The active decks among [ids].
  Future<List<Deck>> deckRows(Set<String> ids) => (_db.select(
    _db.deck,
  )..where((deck) => deck.id.isIn(ids) & deck.deleteBatchId.isNull())).get();

  /// The folded faces of the live cards of [deckId] (BR-TRANSFER-003).
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) async {
    final rows =
        await (_db.select(_db.card)..where(
              (card) =>
                  card.deckId.equals(deckId) & card.deleteBatchId.isNull(),
            ))
            .get();
    return {
      for (final row in rows) (front: row.frontFolded, back: row.backFolded),
    };
  }

  /// How many live cards [deckId] holds.
  Future<int> liveCount(String deckId) {
    final count = _db.card.id.count();
    final query = _db.selectOnly(_db.card)
      ..addColumns([count])
      ..where(_db.card.deckId.equals(deckId) & _db.card.deleteBatchId.isNull());
    return query.map((row) => row.read(count)!).getSingle();
  }

  /// The live cards of [deckId], or those among [ids], by `created_at`, then
  /// `id` (BR-TRANSFER-010).
  Future<List<CardRow>> exportRows(String deckId, Set<String>? ids) =>
      (_db.select(_db.card)
            ..where(
              (card) =>
                  card.deckId.equals(deckId) &
                  card.deleteBatchId.isNull() &
                  (ids == null ? const Constant(true) : card.id.isIn(ids)),
            )
            ..orderBy([
              (card) => OrderingTerm.asc(card.createdAt),
              (card) => OrderingTerm.asc(card.id),
            ]))
          .get();

  Future<void> insertCard({
    required String id,
    required String deckId,
    required CardDraft draft,
    required DateTime now,
  }) => _db
      .into(_db.card)
      .insert(
        _contentOf(draft).copyWith(
          id: Value(id),
          deckId: Value(deckId),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

  Future<void> updateContent(String id, CardDraft draft, DateTime now) =>
      (_db.update(_db.card)..where((card) => card.id.equals(id))).write(
        _contentOf(draft).copyWith(updatedAt: Value(now)),
      );

  /// Their schedule rows, review logs and tag links go with them by cascade.
  Future<void> deleteCards(Set<String> ids) =>
      (_db.delete(_db.card)..where((card) => card.id.isIn(ids))).go();

  Future<void> moveCards(Set<String> ids, String deckId, DateTime now) =>
      (_db.update(_db.card)..where((card) => card.id.isIn(ids))).write(
        CardCompanion(deckId: Value(deckId), updatedAt: Value(now)),
      );

  /// Writes only the cards whose flag differs from [isFlagged].
  Future<void> setFlagged(Set<String> ids, bool isFlagged, DateTime now) {
    final flag = isFlagged ? 1 : 0;
    return (_db.update(_db.card)..where(
          (card) => card.id.isIn(ids) & card.isFlagged.equals(flag).not(),
        ))
        .write(CardCompanion(isFlagged: Value(flag), updatedAt: Value(now)));
  }

  /// Whether [deckId] still holds a live card; tombstones do not count, as in
  /// invariant 29.
  Future<bool> holdsCards(String deckId) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM card WHERE deck_id = ?'
          ' AND delete_batch_id IS NULL) AS holds',
          variables: [Variable<String>(deckId)],
          readsFrom: {_db.card},
        )
        .getSingle();
    return row.read<bool>('holds');
  }

  /// A deck in the Trash keeps its row as it is.
  Future<void> setDeckContentType(
    String deckId,
    String contentType,
    DateTime now,
  ) =>
      (_db.update(_db.deck)..where(
            (deck) => deck.id.equals(deckId) & deck.deleteBatchId.isNull(),
          ))
          .write(
            DeckCompanion(
              contentType: Value(contentType),
              updatedAt: Value(now),
            ),
          );
}

/// The columns a draft sets: sides trimmed with their folded forms computed
/// in Dart (schema.md), blank optional fields stored as null.
CardCompanion _contentOf(CardDraft draft) => CardCompanion(
  front: Value(draft.front.trim()),
  back: Value(draft.back.trim()),
  frontFolded: Value(foldText(draft.front)),
  backFolded: Value(foldText(draft.back)),
  example: Value(_trimmedOrNull(draft.example)),
  hint: Value(_trimmedOrNull(draft.hint)),
  pronunciation: Value(_trimmedOrNull(draft.pronunciation)),
  isFlagged: Value(draft.isFlagged ? 1 : 0),
);

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
