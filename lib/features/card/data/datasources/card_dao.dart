import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';

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

  /// [id] goes to the Trash as the item root of the batch [batchId]
  /// (BR-TRASH-001). The row stays as it is otherwise; only a purge deletes
  /// it, and its schedule, logs and tag links with it.
  Future<void> moveToTrash(String id, String batchId, DateTime now) async {
    await _db.insertDeleteBatch(batchId, 'card', id, now);
    await (_db.update(_db.card)..where((card) => card.id.equals(id))).write(
      CardCompanion(deleteBatchId: Value(batchId)),
    );
  }

  /// The card of [batchId] when the batch holds one: the card the person
  /// deleted, still marked with that batch (BR-TRASH-001). Null when the
  /// batch is gone or holds a deck.
  Future<CardRow?> itemOf(String batchId) async {
    final row = await _db
        .customSelect(
          'SELECT c.* FROM delete_batches b JOIN card c ON c.id = b.root_item_id'
          " AND c.delete_batch_id = b.id WHERE b.id = ? AND b.item_type = 'card'",
          variables: [Variable<String>(batchId)],
          readsFrom: {_db.deleteBatches, _db.card},
        )
        .getSingleOrNull();
    return row == null ? null : _db.card.map(row.data);
  }

  /// The roots of [deckIds], active or in the Trash: a restore checks a card
  /// against the root of its deck, which may be in the Trash (BR-TRASH-006).
  Future<Set<String>> rootIdsOf(Set<String> deckIds) async => {
    for (final deck in await (_db.select(
      _db.deck,
    )..where((deck) => deck.id.isIn(deckIds))).get())
      deck.rootId,
  };

  /// Fires once, then after every write to the decks, the cards or the
  /// batches: where the cards of a Trash selection may go follows all three
  /// (E2).
  Stream<void> restoreTargetChanges() =>
      tableChanges(_db, [_db.deck, _db.card, _db.deleteBatches]);

  /// Whether [deckId] is a deck in the Trash, which a restore refuses as its
  /// target (BR-TRASH-006; `trash_queries.drift`).
  Future<bool> isDeckInTrash(String deckId) =>
      _db.deckIsInTrash(deckId).getSingle();

  /// [cardId] comes back from the batch [batchId] into [deckId], then the
  /// batch row goes, which the key would otherwise cascade (BR-TRASH-007).
  /// A restore stamps [updatedAt], as a move does; an Undo passes none and
  /// the card keeps its own (trash spec D9).
  Future<void> restoreFromBatch(
    String batchId,
    String cardId, {
    required String deckId,
    DateTime? updatedAt,
  }) async {
    await (_db.update(_db.card)..where((card) => card.id.equals(cardId))).write(
      CardCompanion(
        deleteBatchId: const Value(null),
        deckId: Value(deckId),
        updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
      ),
    );
    await (_db.delete(
      _db.deleteBatches,
    )..where((batch) => batch.id.equals(batchId))).go();
  }

  /// The open sessions [batchId] touches end (BR-TRASH-004;
  /// `trash_queries.drift`).
  Future<void> closeSessionsTouching(String batchId, DateTime now) =>
      _db.closeSessionsTouchingBatch(now, batchId);

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
