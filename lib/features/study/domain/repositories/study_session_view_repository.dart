import 'package:memox/features/study/domain/models/study_session_view_model.dart';

/// The session screen's read, apart from the writes of
/// `StudySessionRepository` (graded modes spec §8.5). The one implementation
/// is `StudySessionViewRepositoryImpl` (data layer); the contract exists for
/// ADR-010's reason: domain stays framework-free and tests substitute a fake.
abstract interface class StudySessionViewRepository {
  /// UC-STUDY-001 steps 6–13 (spec §8.2): the session screen, again on every
  /// write it can see; null once the session is gone (A5). It writes nothing
  /// (BR-STUDY-075).
  Stream<StudySessionView?> watchSession(String sessionId);
}
