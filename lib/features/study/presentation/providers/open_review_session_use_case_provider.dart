import 'package:memox/features/study/di/study_entry_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/open_review_session_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'open_review_session_use_case_provider.g.dart';

@riverpod
OpenReviewSessionUseCase openReviewSessionUseCase(Ref ref) =>
    OpenReviewSessionUseCase(ref.watch(studyEntryRepositoryProvider));
