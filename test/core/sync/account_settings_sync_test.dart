import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';
import 'package:memox/features/settings/data/datasources/account_settings_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/card_schedule_sync_dao.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_sync_dao.dart';
import 'package:memox/features/trash/data/datasources/delete_batch_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/review_log_sync_dao.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/tags/data/datasources/tag_sync_dao.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

class _Device {
  _Device(FakeSyncServer server) : db = openTestDatabase() {
    final store = SyncStore(db);
    final cards = CardSyncDao(db);
    coordinator = SyncCoordinator(
      api: server,
      store: store,
      adapters: [
        DeleteBatchSyncDao(db),
        DeckSyncDao(db),
        TagSyncDao(db, store),
        cards,
        CardScheduleSyncDao(db, store),
        ReviewLogSyncDao(db),
        AccountSettingsSyncDao(db),
      ],
    );
  }
  final AppDatabase db;
  late final SyncCoordinator coordinator;
}

Future<AppSetting> _settings(AppDatabase db) => (db.select(
  db.appSettings,
)..where((s) => s.id.equals(appSettingsRowId))).getSingle();

void main() {
  late FakeSyncServer server;
  late _Device a;
  late _Device b;
  setUp(() async {
    server = FakeSyncServer();
    a = _Device(server);
    b = _Device(server);
    await _settings(a.db); // opens both, creating row 1
    await _settings(b.db);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('the adapter reads row 1 in the wire shape', () async {
    await a.db.customStatement(
      "UPDATE app_settings SET card_limit = 30, theme_mode = 'dark', updated_at = 1790553600 WHERE id = 1",
    );
    expect(
      await AccountSettingsSyncDao(a.db).readRow(accountSettingsEntityId),
      {
        'cardLimit': 30,
        'newCardOrder': 'created',
        'themeMode': 'dark',
        'language': 'system',
        'updatedAt': '2026-09-28T00:00:00Z',
      },
    );
  });

  test(
    'a setting changed on one device reaches the other; its reminders stay',
    () async {
      await b.db.customStatement(
        'UPDATE app_settings SET reminder_enabled = 1, reminder_minute_of_day = 480 WHERE id = 1',
      );
      await a.db.customStatement(
        "UPDATE app_settings SET theme_mode = 'dark', language = 'vi' WHERE id = 1",
      );
      await a.coordinator.runOnce();
      await b.coordinator.runOnce();

      final settings = await _settings(b.db);
      expect(settings.themeMode, 'dark');
      expect(settings.language, 'vi');
      expect(settings.reminderEnabled, 1);
      expect(settings.reminderMinuteOfDay, 480);
      expect(await b.db.select(b.db.syncOutbox).get(), isEmpty);
    },
  );

  test(
    'a pulled row without a setting, from a build before the key, leaves that '
    'setting as it is (server sync spec §4.4)',
    () async {
      await a.db.customStatement(
        "UPDATE app_settings SET card_limit = 30, theme_mode = 'dark' WHERE id = 1",
      );
      await SyncStore(a.db).applyingRemote(
        () => AccountSettingsSyncDao(a.db).upsertFromServer({
          'language': 'vi',
          'updatedAt': '2026-09-28T00:00:00Z',
        }, 7),
      );

      final settings = await _settings(a.db);
      expect(settings.language, 'vi');
      expect(settings.cardLimit, 30);
      expect(settings.themeMode, 'dark');
      expect(settings.newCardOrder, 'created');
    },
  );

  test('a pulled card limit outside 1..200 leaves the limit as it is (DEV-214, '
      'BR-STUDY-003)', () async {
    await a.db.customStatement(
      'UPDATE app_settings SET card_limit = 30 WHERE id = 1',
    );
    for (final limit in [0, -5, 201, 10000]) {
      await SyncStore(a.db).applyingRemote(
        () => AccountSettingsSyncDao(a.db).upsertFromServer({
          'cardLimit': limit,
          'themeMode': 'dark',
          'updatedAt': '2026-09-28T00:00:00Z',
        }, 7),
      );
      final settings = await _settings(a.db);
      expect(settings.cardLimit, 30, reason: 'limit $limit is not taken');
      expect(settings.themeMode, 'dark', reason: 'the rest of the row is');
    }
  });

  test('a device on the defaults pushes no settings', () async {
    await b.coordinator.runOnce();
    expect(
      server.pushed.where((k) => k.startsWith('account_settings/')),
      isEmpty,
    );
  });
}
