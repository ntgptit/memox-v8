import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_sync_dao.dart';
import 'package:memox/features/settings/data/datasources/account_settings_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/card_schedule_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/review_log_sync_dao.dart';
import 'package:memox/features/tags/data/datasources/tag_sync_dao.dart';
import 'package:memox/features/trash/data/datasources/delete_batch_sync_dao.dart';

/// The seven adapters a sync test device runs, in the coordinator's order:
/// the library and the account settings, without `lib/app/sync_tables.dart`'s
/// TOPIK attempts (a test that needs them passes its own list).
List<EntitySyncAdapter> deviceSyncAdapters(AppDatabase db) {
  final store = SyncStore(db);
  return [
    DeleteBatchSyncDao(db),
    DeckSyncDao(db),
    TagSyncDao(db, store),
    CardSyncDao(db),
    CardScheduleSyncDao(db, store),
    ReviewLogSyncDao(db),
    AccountSettingsSyncDao(db),
  ];
}
