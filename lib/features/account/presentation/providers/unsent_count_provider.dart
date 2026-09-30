import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unsent_count_provider.g.dart';

/// The changes not sent yet (account UI spec §5.4): what signing out now,
/// offline, would lose.
@riverpod
Future<int> unsentCount(Ref ref) =>
    ref.watch(syncControlProvider).pendingCount();
