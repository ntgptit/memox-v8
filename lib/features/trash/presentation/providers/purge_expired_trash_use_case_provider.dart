import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/purge_expired_trash_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purge_expired_trash_use_case_provider.g.dart';

@riverpod
PurgeExpiredTrashUseCase purgeExpiredTrashUseCase(Ref ref) =>
    PurgeExpiredTrashUseCase(
      ref.watch(trashRepositoryProvider),
      ref.watch(dayClockProvider),
      // R10: the server's clock as of the last sync.
      ref.watch(syncStoreProvider).serverTime,
    );
