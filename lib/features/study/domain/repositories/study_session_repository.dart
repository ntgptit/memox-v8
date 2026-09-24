import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// The one implementation is `StudySessionRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class StudySessionRepository {
  /// UC-STUDY-001 steps 6–9: [answer] on [cardId], the card the session
  /// serves in its current mode and round, or any pending card of a `match`
  /// board (notCurrentCard otherwise, BR-STUDY-042). A turn with an action
  /// is recorded through srs (BR-STUDY-009, BR-STUDY-023); the row then
  /// leaves, comes back or joins the next round (BR-STUDY-005,
  /// BR-STUDY-059, BR-STUDY-062), the cursor moves (BR-STUDY-048), and the
  /// session moves to the next round, the next stage or its end
  /// (BR-STUDY-013, BR-STUDY-069). In a learning session a card that passed
  /// the last stage it takes part in finishes learning (BR-STUDY-053). A
  /// session whose root was reset since it opened is invalidated and the
  /// answer refused as staleGeneration (BR-STUDY-017); any other refusal
  /// writes nothing.
  Future<Outcome<void, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  });

  /// UC-STUDY-001 E3: an open session becomes `failed`/`persistence_error`
  /// (BR-STUDY-018), and the turns it recorded stay (BR-STUDY-019). A
  /// session that has ended, or is gone, is left as it is. Only the E3 path
  /// of `AnswerStudyTurnUseCase` calls it (spec D9).
  Future<void> failSession({required String sessionId, DateTime? now});
}
