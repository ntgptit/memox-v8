import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/local_data_reset.dart';

import '../../support/test_database.dart';

// Auth spec §4: the reset removes the account's data from the device and
// keeps the device's own: the transition record, the welcome flag, the
// reminder, the device id. It queues nothing and is gated by nothing.
Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

Future<void> _seed(AppDatabase db) async {
  for (final sql in [
    "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('b', 'deck', 'D2', 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('C', 'c', 'R', 'R', 2, 'card', 0, 0, 0)",
    "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('K', 'C', 'f', 'b', 0, 0)",
    "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
    "INSERT INTO card_tags (card_id, tag_id) VALUES ('K', 't')",
    "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, answer_count, lapse_count, current_box) VALUES ('K', 'eight_box', 1, 1, 1, 0, 1)",
    "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, \"action\", answered_at) VALUES ('V', 'K', 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 1)",
    "UPDATE app_settings SET card_limit = 35, theme_mode = 'dark', language = 'vi', new_card_order = 'random', reminder_enabled = 1, reminder_minute_of_day = 480, welcome_seen = 1",
    "INSERT INTO sync_rejection (entity_type, entity_id, code, rejected_at) VALUES ('deck', 'R', 'CONFLICT', 0)",
    "INSERT OR REPLACE INTO sync_state (name, value) VALUES ('since', '42'), ('device_id', 'dev-1'), ('last_success_at', '9')",
    "INSERT INTO account_transition (id, op_id, kind, stage, created_at, updated_at) VALUES (1, 'op', 'signOut', 'signedOut', 0, 0)",
  ]) {
    await db.customStatement(sql);
  }
}

void main() {
  test("clears the account's data and keeps the device's", () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await _seed(db);
    db.mutationGate.close();

    await LocalDataReset(db).run();

    for (final table in [
      'deck',
      'card',
      'tags',
      'card_tags',
      'card_schedule',
      'review_log',
      'delete_batches',
      'sync_outbox',
      'sync_rejection',
    ]) {
      expect(await _count(db, table), 0, reason: table);
    }
    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.cardLimit, 20);
    expect(settings.newCardOrder, 'created');
    expect(settings.themeMode, 'system');
    expect(settings.language, 'system');
    expect(settings.reminderEnabled, 1);
    expect(settings.reminderMinuteOfDay, 480);
    expect(settings.welcomeSeen, 1);
    final state = await db
        .customSelect('SELECT name, value FROM sync_state')
        .get();
    expect(
      {
        for (final row in state)
          row.read<String>('name'): row.read<String>('value'),
      },
      {'device_id': 'dev-1'},
    );
    expect(await _count(db, 'account_transition'), 1);
  });

  test('a second run is a no-op', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await _seed(db);
    final reset = LocalDataReset(db);

    await reset.run();
    await reset.run();

    expect(await _count(db, 'deck'), 0);
    expect(await _count(db, 'sync_outbox'), 0);
  });
}
