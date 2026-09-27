import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/providers/watch_study_session_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_view_provider.g.dart';

/// A session as its screen reads it (screens 16 to 21), again on every
/// write; `Rejected(notFound)` once it is gone.
@riverpod
Stream<Outcome<StudySessionView, StudyRejection>> studySessionView(
  Ref ref,
  String sessionId,
) => ref.watch(watchStudySessionUseCaseProvider)(sessionId: sessionId);
