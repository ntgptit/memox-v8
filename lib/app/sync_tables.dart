import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/settings/data/datasources/account_settings_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/card_schedule_sync_dao.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_sync_dao.dart';
import 'package:memox/features/trash/data/datasources/delete_batch_sync_dao.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/features/srs/data/datasources/review_log_sync_dao.dart';
import 'package:memox/features/tags/data/datasources/tag_sync_dao.dart';
import 'package:memox/features/settings/data/datasources/settings_dao.dart';

/// The synced tables the app ships, parent before child: the list order is
/// the push and the apply order (DEV-173).
List<EntitySyncAdapter> appSyncAdapters(Ref ref) {
  final db = ref.watch(databaseProvider);
  final store = ref.watch(syncStoreProvider);
  final now = ref.watch(dayClockProvider).now;
  return [
    DeleteBatchSyncDao(db),
    DeckSyncDao(db),
    TagSyncDao(db, store, now: now),
    CardSyncDao(db),
    CardScheduleSyncDao(db, store, now: now),
    ReviewLogSyncDao(db),
    AccountSettingsSyncDao(db),
  ];
}

/// The settings feature's reset of the synced settings (DEV-173).
Future<void> Function() appSyncedSettingsReset(Ref ref) {
  final dao = SettingsDao(ref.watch(databaseProvider));
  final now = ref.watch(dayClockProvider).now;
  return () => dao.resetSyncedDefaults(now());
}

/// What `main.dart` and the tests install so core's sync and account reset
/// see the app's tables.
final syncTableOverrides = [
  syncAdaptersProvider.overrideWith(appSyncAdapters),
  syncedSettingsResetProvider.overrideWith(appSyncedSettingsReset),
];
