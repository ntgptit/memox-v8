import 'package:drift/drift.dart' show UpdateKind, Variable;
import 'package:memox/core/database/app_database.dart';

import 'trash_fixtures.dart';

// Raw rows for the tests of `tags`, which imports no feature (ADR-011), so
// its tests do not either. Every write names the tables it touches and, for
// an update, its kind, as the app's writes do: drift takes a write of unknown
// kind for a possible delete and tells every table whose key cascades from
// it, so a stream deaf to `card` would still hear a card move.

/// A root `r` with the card sub-decks `leaf` and `other`.
Future<void> insertTagDecks(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, '
    'scheduler_version, generation, sibling_position, created_at, updated_at) '
    "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
  );
  for (final (index, id) in ['leaf', 'other'].indexed) {
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'sibling_position, created_at, updated_at) '
      "VALUES (?, ?, 'r', 'r', 2, 'card', ?, 0, 0)",
      [id, id, index],
    );
  }
}

/// An active card in [deckId].
Future<void> insertTagCard(
  AppDatabase db,
  String id, {
  String deckId = 'leaf',
}) => db.customInsert(
  'INSERT INTO card (id, deck_id, front, back, created_at, updated_at) '
  "VALUES (?, ?, 'f', 'b', 0, 0)",
  variables: [Variable<String>(id), Variable<String>(deckId)],
  updates: {db.card},
);

/// The tag [name], folded as BR-TAG-001 folds it, carried by [cardIds].
Future<void> insertTag(
  AppDatabase db,
  String id,
  String name, {
  List<String> cardIds = const [],
  String? ownerId,
}) async {
  await db.customInsert(
    'INSERT INTO tags (id, name, name_folded, owner_id, created_at) '
    'VALUES (?, ?, ?, ?, 0)',
    variables: [
      Variable<String>(id),
      Variable<String>(name),
      Variable<String>(name.trim().toLowerCase()),
      Variable<String>(ownerId),
    ],
    updates: {db.tags},
  );
  for (final cardId in cardIds) {
    await db.customInsert(
      'INSERT INTO card_tags (card_id, tag_id) VALUES (?, ?)',
      variables: [Variable<String>(cardId), Variable<String>(id)],
      updates: {db.cardTags},
    );
  }
}

/// [cardId] into the Trash as the batch [batchId], or back from it when
/// [batchId] is null.
Future<void> setCardBatch(
  AppDatabase db,
  String cardId,
  String? batchId,
) async {
  if (batchId != null) {
    await insertDeleteBatch(db, batchId, itemType: 'card', rootItemId: cardId);
  }
  await db.customUpdate(
    'UPDATE card SET delete_batch_id = ? WHERE id = ?',
    variables: [Variable<String>(batchId), Variable<String>(cardId)],
    updates: {db.card},
    updateKind: UpdateKind.update,
  );
}

/// [cardId] moved to [deckId], as a card move writes it.
Future<void> setCardDeck(AppDatabase db, String cardId, String deckId) =>
    db.customUpdate(
      'UPDATE card SET deck_id = ? WHERE id = ?',
      variables: [Variable<String>(deckId), Variable<String>(cardId)],
      updates: {db.card},
      updateKind: UpdateKind.update,
    );
