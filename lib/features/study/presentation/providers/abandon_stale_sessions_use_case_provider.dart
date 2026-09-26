import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/abandon_stale_sessions_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'abandon_stale_sessions_use_case_provider.g.dart';

@riverpod
AbandonStaleSessionsUseCase abandonStaleSessionsUseCase(Ref ref) =>
    AbandonStaleSessionsUseCase(ref.watch(studySessionRepositoryProvider));
