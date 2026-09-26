import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/providers/watch_study_session_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_provider.g.dart';

/// [sessionId]'s screen, again after every turn; notFound once its deck is
/// in the Trash or the session is gone (UC-STUDY-001 A5, E5).
@riverpod
Stream<Outcome<StudySessionView, StudyRejection>> studySession(
  Ref ref,
  String sessionId,
) => ref.watch(watchStudySessionUseCaseProvider)(sessionId: sessionId);
