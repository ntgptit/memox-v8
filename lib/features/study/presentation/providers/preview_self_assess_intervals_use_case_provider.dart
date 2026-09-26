import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/preview_self_assess_intervals_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'preview_self_assess_intervals_use_case_provider.g.dart';

@riverpod
PreviewSelfAssessIntervalsUseCase previewSelfAssessIntervalsUseCase(Ref ref) =>
    PreviewSelfAssessIntervalsUseCase(
      ref.watch(scheduleRepositoryProvider),
      ref.watch(dayClockProvider),
    );
