import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_server_time_provider.g.dart';

/// The server's time as of the last sync, or null when this device never
/// synced: with the device clock it gives the purge clock the rows are
/// labelled by (BR-TRASH-009, R10). Read each time the Trash opens.
@riverpod
Future<DateTime?> trashServerTime(Ref ref) =>
    ref.watch(syncStoreProvider).serverTime();
