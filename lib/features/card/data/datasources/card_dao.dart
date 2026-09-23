import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/text/folded_text.dart';

/// Row access for `card`, plus the reads and writes of the owning `deck` row
/// that card writes need. It returns Drift rows, never domain entities, and
/// runs inside the caller's transaction.
final class CardDao {
  CardDao(this._db);

  final AppDatabase _db;

  Future<CardRow?> findRow(String id) => (_db.select(
    _db.card,
  )..where((card) => card.id.equals(id))).getSingleOrNull();

  Future<Deck?> deckRow(String id) => (_db.select(
    _db.deck,
  )..where((deck) => deck.id.equals(id))).getSingleOrNull();

  /// Inserts a card with trimmed sides, their folded forms computed in Dart —
  /// SQLite's `lower()` is ASCII-only (schema.md) — and blank optional fields
  /// stored as null.
  Future<void> insertCard({
    required String id,
    required String deckId,
    required String front,
    required String back,
    required String? example,
    required String? hint,
    required String? pronunciation,
    required DateTime now,
  }) => _db
      .into(_db.card)
      .insert(
        CardCompanion.insert(
          id: id,
          deckId: deckId,
          front: front.trim(),
          back: back.trim(),
          frontFolded: Value(foldText(front)),
          backFolded: Value(foldText(back)),
          example: Value(_trimmedOrNull(example)),
          hint: Value(_trimmedOrNull(hint)),
          pronunciation: Value(_trimmedOrNull(pronunciation)),
          createdAt: now,
          updatedAt: now,
        ),
      );

  /// Its schedule row, review log and tag links go with it by cascade.
  Future<void> deleteCard(String id) =>
      (_db.delete(_db.card)..where((card) => card.id.equals(id))).go();

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

  Future<void> setDeckContentType(
    String deckId,
    String contentType,
    DateTime now,
  ) => (_db.update(_db.deck)..where((deck) => deck.id.equals(deckId))).write(
    DeckCompanion(contentType: Value(contentType), updatedAt: Value(now)),
  );
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
