import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/watch_deck_level_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_deck_level_use_case_provider.g.dart';

@riverpod
WatchDeckLevelUseCase watchDeckLevelUseCase(Ref ref) => WatchDeckLevelUseCase(
  ref.watch(deckRepositoryProvider),
  ref.watch(dayClockProvider),
);
