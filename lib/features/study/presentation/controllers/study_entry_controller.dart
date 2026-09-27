import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/providers/resume_study_session_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_entry_controller.g.dart';

/// The Study Entry writes. P1 has one: Continue on today's `in_progress`
/// session (UC-STUDY-001 A3b); Learn and Review join as their stages are
/// built (spec §3).
@riverpod
class StudyEntryController extends _$StudyEntryController {
  @override
  void build() {}

  Future<Outcome<void, StudyRejection>> resume(String sessionId) =>
      ref.read(resumeStudySessionUseCaseProvider)(sessionId: sessionId);
}
