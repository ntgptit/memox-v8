import 'package:memox/features/study/di/study_entry_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/open_learning_session_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'open_learning_session_use_case_provider.g.dart';

@riverpod
OpenLearningSessionUseCase openLearningSessionUseCase(Ref ref) =>
    OpenLearningSessionUseCase(ref.watch(studyEntryRepositoryProvider));
