import 'package:memox/features/study/di/study_session_view_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/watch_study_session_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_study_session_use_case_provider.g.dart';

@riverpod
WatchStudySessionUseCase watchStudySessionUseCase(Ref ref) =>
    WatchStudySessionUseCase(ref.watch(studySessionViewRepositoryProvider));
