import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/save_recall_time_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'save_recall_time_use_case_provider.g.dart';

@riverpod
SaveRecallTimeUseCase saveRecallTimeUseCase(Ref ref) =>
    SaveRecallTimeUseCase(ref.watch(studySessionRepositoryProvider));
