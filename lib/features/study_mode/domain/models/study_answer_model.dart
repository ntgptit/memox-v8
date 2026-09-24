/// What the person did on one card (UC-STUDY-001 step 6). Package 2b gives
/// the graded modes their own inputs; here they hand in a verdict.
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

/// A graded mode's verdict (BR-MODE-011, BR-MODE-012).
final class GradedAnswer extends StudyAnswer {
  const GradedAnswer({required this.isCorrect});

  final bool isCorrect;
}
