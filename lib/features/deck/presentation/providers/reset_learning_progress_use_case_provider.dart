import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/srs/domain/usecases/reset_learning_progress_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reset_learning_progress_use_case_provider.g.dart';

@riverpod
ResetLearningProgressUseCase resetLearningProgressUseCase(Ref ref) =>
    ResetLearningProgressUseCase(ref.watch(scheduleRepositoryProvider));
