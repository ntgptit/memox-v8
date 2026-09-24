import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_reset_learning_summary_use_case_provider.g.dart';

@riverpod
GetResetLearningSummaryUseCase getResetLearningSummaryUseCase(Ref ref) =>
    GetResetLearningSummaryUseCase(ref.watch(scheduleRepositoryProvider));
