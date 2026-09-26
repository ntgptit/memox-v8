import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/watch_study_home_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_study_home_use_case_provider.g.dart';

@riverpod
WatchStudyHomeUseCase watchStudyHomeUseCase(Ref ref) => WatchStudyHomeUseCase(
  ref.watch(studyHomeRepositoryProvider),
  ref.watch(dayClockProvider),
);
