import 'package:memox/core/database/app_database.dart';

// Raw SQL rows the sync tests start from: the shapes the triggers and the
// adapters read, written without the repositories so a test owns every column.

/// A root deck [id] (depth 1, its own root, `sm2`).
Future<void> insertRootDeck(
  AppDatabase db,
  String id, {
  String name = 'r',
}) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, ?, NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  [id, name, id],
);

/// A deck [id] one level under the root deck [parent], with [contentType].
Future<void> insertChildDeck(
  AppDatabase db,
  String id,
  String parent, {
  String contentType = 'unset',
}) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
  "sibling_position, created_at, updated_at) "
  "VALUES (?, 'c', ?, ?, 2, ?, 0, 0, 0)",
  [id, parent, parent, contentType],
);

/// A card [id] in [deck].
Future<void> insertCard(
  AppDatabase db,
  String id,
  String deck, {
  String front = 'f',
}) => db.customStatement(
  "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
  "VALUES (?, ?, ?, 'b', 0, 0)",
  [id, deck, front],
);
