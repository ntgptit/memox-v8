import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

/// UC-STUDY-001 A3b: when the app starts, the sessions left open on an
/// earlier local day close as `interrupted` (BR-STUDY-072).
final class AbandonStaleSessionsUseCase {
  const AbandonStaleSessionsUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<void> call() => _sessions.abandonStaleSessions();
}
