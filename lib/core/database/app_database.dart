import 'package:drift/drift.dart';
import 'package:memox/core/database/migrations/nfc_text_migration.dart';
import 'package:memox/core/database/schema_versions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  include: {
    'package:memox/core/database/tables/deck.drift',
    'package:memox/core/database/tables/card.drift',
    'package:memox/core/database/tables/tags.drift',
    'package:memox/core/database/tables/srs.drift',
    'package:memox/core/database/tables/study.drift',
    'package:memox/core/database/tables/settings.drift',
    'package:memox/core/database/tables/trash.drift',
    'package:memox/core/database/tables/sync.drift',
    'package:memox/core/database/queries/card_queries.drift',
    'package:memox/core/database/queries/deck_queries.drift',
    'package:memox/core/database/queries/trash_queries.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  int get schemaVersion => 8;

  /// Each step works on the schema of its own version (`schema_versions.dart`,
  /// generated from `drift_schemas/`), never on today's tables, and a shipped
  /// step never changes (`.claude/skills/flutter-drift/references/
  /// migrations.md`).
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        // Package 2b: the fill hint and the match board on the queue row, and
        // the stored options of a guess question (graded modes spec §6).
        await m.addColumn(
          schema.studyQueueItems,
          schema.studyQueueItems.hintShown,
        );
        await m.addColumn(
          schema.studyQueueItems,
          schema.studyQueueItems.meaningSlot,
        );
        await m.createTable(schema.studyGuessOptions);
        await m.createIndex(schema.idxStudyGuessOptionsOption);
      },
      from2To3: (m, schema) async {
        // Package 7: the Trash. delete_batch_id becomes a key to the batch,
        // which SQLite adds only by rebuilding deck and card; no row changes,
        // since no build before v3 writes the column (trash spec §5.2).
        await m.createTable(schema.deleteBatches);
        await m.createIndex(schema.idxDeleteBatchesDeleted);
        await m.alterTable(TableMigration(schema.deck));
        await m.alterTable(TableMigration(schema.card));
        await m.createIndex(schema.idxDeckDeleteBatch);
        await m.createIndex(schema.idxCardDeleteBatch);
      },
      from3To4: (m, schema) async {
        // ADR-013: sync. The outbox, its state, the acknowledged version on
        // each synced row, and the triggers that capture every local write
        // (app deck-sync spec §3). Existing rows are queued so the first sync
        // uploads the library: batches first, then decks parents-first.
        await m.createTable(schema.syncOutbox);
        await m.createTable(schema.syncState);
        await m.addColumn(schema.deck, schema.deck.serverVersion);
        await m.addColumn(
          schema.deleteBatches,
          schema.deleteBatches.serverVersion,
        );
        await m.createTrigger(schema.deckSyncInsert);
        await m.createTrigger(schema.deckSyncUpdate);
        await m.createTrigger(schema.deckSyncDelete);
        await m.createTrigger(schema.deleteBatchesSyncInsert);
        await m.createTrigger(schema.deleteBatchesSyncUpdate);
        await m.createTrigger(schema.deleteBatchesSyncDelete);
        await customStatement(
          _seedOutbox('delete_batch', 'delete_batches', 'id'),
        );
        await customStatement(_seedOutbox('deck', 'deck', 'depth, id'));
      },
      from4To5: (m, schema) async {
        // G1 (BE-C5): user text in NFC, folded columns recomputed, tags that
        // become one name merged; no structure changes (local backend spec
        // 2026-09-27 §4).
        await normalizeStoredText(this);
      },
      from5To6: (m, schema) async {
        // SB-U1: refused sync rows are recorded (sync status spec §4). A new,
        // empty table; no row changes.
        await m.createTable(schema.syncRejection);
      },
      from6To7: (m, schema) async {
        // SB-S2: cards sync (library and study sync spec §3.1). Existing cards
        // are queued, oldest first, so the first run uploads them.
        await m.addColumn(schema.card, schema.card.serverVersion);
        await m.createTrigger(schema.cardSyncInsert);
        await m.createTrigger(schema.cardSyncUpdate);
        await m.createTrigger(schema.cardSyncDelete);
        await customStatement(_seedOutbox('card', 'card', 'created_at, id'));
      },
      from7To8: (m, schema) async {
        // SB-S3: tags sync, and a card's links travel on the card (library
        // and study sync spec §3.2). Tags are queued, then every tagged card,
        // so the links reach the server; an already-queued card stays queued.
        await m.addColumn(schema.tags, schema.tags.serverVersion);
        await m.createTrigger(schema.tagsSyncInsert);
        await m.createTrigger(schema.tagsSyncUpdate);
        await m.createTrigger(schema.tagsSyncDelete);
        await m.createTrigger(schema.cardTagsSyncInsert);
        await m.createTrigger(schema.cardTagsSyncDelete);
        await customStatement(_seedOutbox('tag', 'tags', 'created_at, id'));
        await customStatement(
          '${_seedOutbox('card', '(SELECT DISTINCT card_id AS id FROM card_tags)', 'id')} '
          'ON CONFLICT (entity_type, entity_id) DO NOTHING',
        );
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // BR-SETTINGS-001: the one settings row exists from the first open, so
      // every surface reads real values. It changes nothing once it exists.
      await into(appSettings).insert(
        AppSettingsCompanion.insert(
          id: const Value(appSettingsRowId),
          updatedAt: _now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    },
  );
}

/// The id of the one `app_settings` row: `CHECK (id = 1)` keeps the table at
/// this row (BR-SETTINGS-001).
const appSettingsRowId = 1;

/// Queues every existing row of [table] for upload, in [order].
String _seedOutbox(String entityType, String table, String order) =>
    'INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at) '
    "SELECT lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || "
    "substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || "
    "substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))), "
    "'$entityType', id, 'upsert', CAST(strftime('%s', 'now') AS INTEGER) "
    'FROM $table ORDER BY $order';
