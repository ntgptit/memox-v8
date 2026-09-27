import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/library_upload_seed.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = openTestDatabase();
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, study_config, sibling_position, created_at, updated_at) VALUES "
      "('R2', 'Second', NULL, 'R2', 1, 'deck', 'eight_box', 1, 1, NULL, 1, 0, 0), "
      "('R1', 'First', NULL, 'R1', 1, 'deck', 'sm2', 1, 1, '{\"cardLimit\":5}', 0, 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES "
      "('BD', 'deck', 'T', 100), ('BC', 'card', 'k2', 200), ('BX', 'deck', 'A', 50)",
    );
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, delete_batch_id, "
      "sibling_position, created_at, updated_at) VALUES "
      "('A', 'Cards', 'R1', 'R1', 2, 'card', NULL, 0, 0, 0), "
      "('T', 'Trashed', 'R1', 'R1', 2, 'unset', 'BD', 1, 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, is_flagged, delete_batch_id, created_at, updated_at) VALUES "
      "('k1', 'A', 'a', 'b', 1, NULL, 1, 1), ('k2', 'A', 'c', 'd', 0, 'BC', 2, 2)",
    );
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, sibling_position, created_at, updated_at, server_version) "
      "VALUES ('OLD', 'Acked', NULL, 'OLD', 1, 'deck', 'sm2', 1, 1, 2, 0, 0, 9)",
    );
    await db.customStatement('DELETE FROM sync_outbox');
  });
  tearDown(() => db.close());

  test('the library becomes commands in causal order', () async {
    await seedLibraryUpload(db);

    final entries = await (db.select(
      db.syncOutbox,
    )..orderBy([(o) => OrderingTerm(expression: o.seq)])).get();
    String label(SyncOutboxEntry e) {
      if (e.kind == 'patch') {
        return '${e.entityType}/${e.patchGroup} ${e.entityId}';
      }
      final payload = jsonDecode(e.payload!) as Map<String, Object?>;
      return '${e.commandType} ${payload['id'] ?? payload['deckId'] ?? payload['batchId'] ?? (payload['items'] as List).single['cardId']}';
    }

    expect(entries.map(label).toList(), [
      'CREATE_ROOT_DECK R1',
      'CREATE_ROOT_DECK R2',
      'CREATE_SUB_DECK A',
      'CREATE_SUB_DECK T',
      'CREATE_CARD k1',
      'CREATE_CARD k2',
      'card/flag k1',
      'deck/study_options R1',
      'DELETE_DECK T',
      'DELETE_CARDS k2',
    ]);
    final deleteDeck = jsonDecode(entries[8].payload!) as Map<String, Object?>;
    expect(deleteDeck['batchId'], 'BD');
    expect(deleteDeck['deletedAt'], isNotNull);
  });
}
