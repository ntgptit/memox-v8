/// What the person did on one card (UC-STUDY-001 step 6): each mode takes its
/// own input (graded modes spec §7.1).
sealed class StudyAnswer {
  const StudyAnswer();
}

/// `browse`: moving on from the card (BR-MODE-005).
final class AdvanceAnswer extends StudyAnswer {
  const AdvanceAnswer();
}

/// `self_assess`: the action the person pressed (BR-MODE-011).
final class SelfAssessAnswer extends StudyAnswer {
  const SelfAssessAnswer(this.action);

  final Object action;
}

/// A graded mode's verdict (BR-MODE-011, BR-MODE-012). Package 2a's stand-in
/// for the real inputs below; the session stops taking it in Task 6.
final class GradedAnswer extends StudyAnswer {
  const GradedAnswer({required this.isCorrect});

  final bool isCorrect;
}

/// `fill`: the term the person typed. It is judged and never stored
/// (BR-STUDY-030).
final class FillAnswer extends StudyAnswer {
  const FillAnswer(this.typed);

  final String typed;
}

/// `recall`: the person's self-assessment once the answer is revealed, or the
/// end of the turn's time (BR-STUDY-032, BR-STUDY-065).
final class RecallAnswer extends StudyAnswer {
  const RecallAnswer(this.outcome);

  final RecallOutcome outcome;
}

enum RecallOutcome { remembered, forgot, timedOut }

/// `guess`: the option chosen, by card id (BR-STUDY-041).
final class GuessAnswer extends StudyAnswer {
  const GuessAnswer(this.chosenCardId);

  final String chosenCardId;
}

/// `match`: the meaning paired with the turn's card, which owns the term
/// (BR-STUDY-062).
final class MatchAnswer extends StudyAnswer {
  const MatchAnswer(this.meaningCardId);

  final String meaningCardId;
}
