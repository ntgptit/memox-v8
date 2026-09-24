import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_deck_move_targets_use_case_provider.g.dart';

@riverpod
WatchDeckMoveTargetsUseCase watchDeckMoveTargetsUseCase(Ref ref) =>
    WatchDeckMoveTargetsUseCase(ref.watch(deckRepositoryProvider));
