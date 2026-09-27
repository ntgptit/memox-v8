import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_deck_restore_targets_use_case_provider.g.dart';

@riverpod
WatchDeckRestoreTargetsUseCase watchDeckRestoreTargetsUseCase(Ref ref) =>
    WatchDeckRestoreTargetsUseCase(ref.watch(deckRepositoryProvider));
