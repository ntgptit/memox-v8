import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/study/di/study_entry_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/watch_study_entry_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_study_entry_use_case_provider.g.dart';

@riverpod
WatchStudyEntryUseCase watchStudyEntryUseCase(Ref ref) =>
    WatchStudyEntryUseCase(
      ref.watch(studyEntryRepositoryProvider),
      ref.watch(dayClockProvider),
    );
