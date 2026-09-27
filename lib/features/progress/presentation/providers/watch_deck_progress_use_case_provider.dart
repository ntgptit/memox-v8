import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/usecases/watch_deck_progress_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_deck_progress_use_case_provider.g.dart';

@riverpod
WatchDeckProgressUseCase watchDeckProgressUseCase(Ref ref) =>
    WatchDeckProgressUseCase(
      ref.watch(progressRepositoryProvider),
      ref.watch(dayClockProvider),
    );
