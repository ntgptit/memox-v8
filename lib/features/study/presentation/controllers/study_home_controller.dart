import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/presentation/providers/resume_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/states/study_home_resume_state.dart';
import 'package:memox/shared/support/held_run.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_home_controller.g.dart';

/// Study Home's one write: taking up today's session (UC-STUDY-002, FE-A8
/// H3). The state is whether a Resume runs; a second one meanwhile is
/// dropped (BR-STUDY-004). Everything else on the screen is read-only
/// (BR-STUDY-075).
@riverpod
class StudyHomeController extends _$StudyHomeController {
  @override
  bool build() => false;

  /// Null when dropped because one already runs.
  Future<StudyHomeResumeResult?> resume(String sessionId) async {
    if (state) return null;
    state = true;
    late StudyHomeResumeResult result;
    await runHeld(
      () async {
        result = switch (await ref.read(resumeStudySessionUseCaseProvider)(
          sessionId: sessionId,
        )) {
          Ok() => ResumeOpened(sessionId),
          Rejected() => const ResumeRefused(),
        };
      },
      // A bug ends as a Failure does: nothing changed.
      onFailed: (_) => result = const ResumeFailed(),
    );
    if (!ref.mounted) return result;
    state = false;
    return result;
  }
}
