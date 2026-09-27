/// BE-E7 spec D2: every deck, card and trash-batch id a write changes is
/// recorded in the TEMP table `sync_changed`, per connection, for the command
/// that describes the write. The triggers never write the outbox.
library;

const _tables = <(String table, String entityType)>[
  ('deck', 'deck'),
  ('card', 'card'),
  ('delete_batches', 'delete_batch'),
];

const _events = <(String event, String row)>[
  ('INSERT', 'new'),
  ('UPDATE', 'new'),
  ('DELETE', 'old'),
];

/// The statements that create the collector; safe to run on every open.
List<String> syncChangeCollectorStatements() => [
  'CREATE TEMP TABLE IF NOT EXISTS sync_changed ('
      'entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, '
      'PRIMARY KEY (entity_type, entity_id))',
  for (final (table, entityType) in _tables)
    for (final (event, row) in _events)
      'CREATE TEMP TRIGGER IF NOT EXISTS ${table}_changed_${event.toLowerCase()} '
          'AFTER $event ON $table BEGIN '
          "INSERT OR IGNORE INTO sync_changed VALUES ('$entityType', $row.id); END",
];
