import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// The writes of a session; its screen reads through
/// `StudySessionViewRepository`. The one implementation is
/// `StudySessionRepositoryImpl` (data layer). The contract exists for
/// ADR-010's reason: domain stays framework-free and tests substitute a fake.
abstract interface class StudySessionRepository {
  /// UC-STUDY-001 steps 6–9: [answer] on [cardId], the card the session
  /// serves in its current mode and round, or a pending pair of the current
  /// `match` board (notCurrentCard otherwise, BR-STUDY-042, BR-STUDY-049).
  /// The mode judges the answer against the card and what its row keeps
  /// (graded modes spec §7): a blank `fill` answer, a `recall` answer out of
  /// turn with its reveal, a blocked `guess` question, a card that is not
  /// one of its options and a meaning off the board are refused. A turn with
  /// an action is recorded through srs with what its mode adds (BR-STUDY-009,
  /// BR-STUDY-023, BR-STUDY-027, BR-STUDY-028, BR-STUDY-034); the row then
  /// leaves, comes back or joins the next round (BR-STUDY-005,
  /// BR-STUDY-059, BR-STUDY-062), the cursor moves (BR-STUDY-048), and the
  /// session moves to the next round, the next stage or its end
  /// (BR-STUDY-013, BR-STUDY-069). In a learning session a card that passed
  /// the last stage it takes part in finishes learning (BR-STUDY-053). A
  /// session whose root was reset since it opened is invalidated and the
  /// answer refused as staleGeneration (BR-STUDY-017); any other refusal
  /// writes nothing. The result says whether a graded answer was right.
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  });

  /// `recall`: the answer of the turn on [cardId] is shown before the time
  /// runs out. It records nothing and moves nothing: the time stops at the
  /// smaller of what is stored and [remainingMs], and the turn waits for the
  /// person's self-assessment (BR-STUDY-065, BR-STUDY-036). A second reveal
  /// changes nothing. It is refused as a turn would be: notFound,
  /// sessionClosed, staleGeneration (the session is invalidated),
  /// notCurrentCard, answerDoesNotFitMode (graded modes spec §8.3).
  Future<Outcome<void, StudyRejection>> revealRecallAnswer({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  });

  /// `recall`: the time left of the turn on [cardId], kept for Continue. It
  /// never grows, and once the answer is revealed it stays where it stopped
  /// (BR-STUDY-036). Refused as [revealRecallAnswer] is.
  Future<Outcome<void, StudyRejection>> saveRecallTime({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  });

  /// `fill`: the hint of the turn on [cardId] is shown, and the turn records
  /// that it was, without its result changing (BR-STUDY-028). noHint when the
  /// card has none; otherwise refused as [revealRecallAnswer] is.
  Future<Outcome<void, StudyRejection>> showFillHint({
    required String sessionId,
    required String cardId,
    DateTime? now,
  });

  /// UC-STUDY-001 E3: an open session becomes `failed`/`persistence_error`
  /// (BR-STUDY-018), and the turns it recorded stay (BR-STUDY-019). A
  /// session that has ended, or is gone, is left as it is. Only the E3 path
  /// of `AnswerStudyTurnUseCase` calls it (spec D9).
  Future<void> failSession({required String sessionId, DateTime? now});

  /// UC-STUDY-001 A3: the person leaves an open session. It becomes
  /// `abandoned`/`user_exit` (BR-STUDY-014) and keeps its turns
  /// (BR-STUDY-019); sessionClosed when it has ended, notFound when it is
  /// gone.
  Future<Outcome<void, StudyRejection>> abandonSession({
    required String sessionId,
    DateTime? now,
  });

  /// UC-STUDY-001 A3b, Continue. A session of an earlier local day is closed
  /// as `abandoned`/`interrupted` and refused as sessionExpired
  /// (BR-STUDY-072); one whose root was reset since is invalidated and
  /// refused as staleGeneration (BR-STUDY-017). Otherwise the session is
  /// settled: when the cards left in its current round were deleted, it
  /// moves on as after a turn, and completes with nothing left (spec D12).
  Future<Outcome<void, StudyRejection>> resumeSession({
    required String sessionId,
    DateTime? now,
  });

  /// UC-STUDY-001 A3b: every open session that started before today's
  /// local midnight becomes `abandoned`/`interrupted` (BR-STUDY-072). The app
  /// calls it when it starts; no read does (BR-STUDY-075).
  Future<void> abandonStaleSessions({DateTime? now});
}
