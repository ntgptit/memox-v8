import 'package:drift/drift.dart'
    show QueryExecutor, QueryInterceptor, UpdateKind, Variable;
import 'package:drift/native.dart' show SqliteException;
import 'package:memox/core/database/app_database.dart';

import 'srs_fixtures.dart';
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

/// `s-card`, in a tree of its own, with a schedule row, a review log row and
/// a place in the queue of an in-progress session: rows a tag write leaves
/// as they are (BR-TAG-009).
Future<void> insertStudiedCard(AppDatabase db) async {
  final (_, cardId, sessionId) = await insertStudyTree(db, 's');
  await db.customStatement(
    'INSERT INTO study_queue_items (session_id, mode, card_id, position, '
    "status) VALUES (?, 'self_assess', ?, 0, 'pending')",
    [sessionId, cardId],
  );
  await db.customStatement(
    'INSERT INTO review_log (id, card_id, session_id, scheduler_type, '
    'generation, kind, mode, "action", answered_at) VALUES '
    "('s-log', ?, ?, 'eight_box', 1, 'learning', 'self_assess', "
    "'remembered', 0)",
    [cardId, sessionId],
  );
}

/// Every row outside `tags` and `card_tags`, table by table in rowid order:
/// a Tag Management write leaves it as it was (BR-TAG-009).
Future<Map<String, List<Map<String, Object?>>>> rowsOutsideTags(
  AppDatabase db,
) async {
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' AND name NOT IN ('tags', 'card_tags') "
        'ORDER BY name',
      )
      .get();
  return {
    for (final name in [for (final row in tables) row.read<String>('name')])
      name: [
        for (final row
            in await db
                .customSelect('SELECT * FROM "$name" ORDER BY rowid')
                .get())
          row.data,
      ],
  };
}

/// Every tag as (id, name, name_folded), by id.
Future<List<(String, String, String)>> tagRowsOf(AppDatabase db) async => [
  for (final row
      in await db
          .customSelect('SELECT id, name, name_folded FROM tags ORDER BY id')
          .get())
    (
      row.read<String>('id'),
      row.read<String>('name'),
      row.read<String>('name_folded'),
    ),
];

/// Every link as `card:tag`, by card then tag.
Future<List<String>> linksOf(AppDatabase db) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT card_id, tag_id FROM card_tags ORDER BY card_id, tag_id',
          )
          .get())
    '${row.read<String>('card_id')}:${row.read<String>('tag_id')}',
];

/// Fails the statement that deletes a row of `tags`, the way a full disk
/// does. In a merge it runs after the links moved.
final class FailingTagDelete extends QueryInterceptor {
  static final _deletesTag = RegExp(r'^DELETE FROM "?tags"?\s');

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _failIfTagDelete(statement);
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _failIfTagDelete(statement);
    return super.runDelete(executor, statement, args);
  }

  void _failIfTagDelete(String statement) {
    if (!_deletesTag.hasMatch(statement)) return;
    throw SqliteException(
      extendedResultCode: 13,
      message: 'database or disk is full',
    );
  }
}
