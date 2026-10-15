import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

/// The snapshot one answer takes at submit (BR-TOPIK-013).
final class TopikAnswerScore {
  const TopikAnswerScore({
    required this.questionNo,
    required this.correctIdx,
    required this.points,
    required this.pointsEarned,
    required this.questionType,
    required this.status,
  });

  final int questionNo;
  final int correctIdx;
  final int points;
  final int pointsEarned;
  final TopikQuestionType questionType;
  final TopikAnswerStatus status;
}

/// An attempt scored against its test (BR-TOPIK-013, spec §5.3).
final class TopikAttemptScore {
  const TopikAttemptScore({
    required this.answers,
    required this.score,
    required this.maxScore,
    required this.correctCount,
    required this.answeredCount,
  });

  /// One per question, in question order.
  final List<TopikAnswerScore> answers;
  final int score;
  final int maxScore;
  final int correctCount;
  final int answeredCount;

  int get questionCount => answers.length;
}

/// Scores [selections] (question number → chosen option, or null when
/// unanswered) against the current content of [test]: the content at submit
/// is the one that scores (BR-TOPIK-013). The keys must be exactly the
/// question numbers of [test]; the store checks that first and refuses the
/// submit otherwise (BR-TOPIK-019).
TopikAttemptScore scoreTopikAttempt(TopikTest test, Map<int, int?> selections) {
  final numbers = {for (final question in test.questions) question.no};
  if (numbers.length != selections.length ||
      !numbers.containsAll(selections.keys)) {
    throw ArgumentError.value(
      selections.keys.toList(),
      'selections',
      'must be exactly the question numbers of ${test.testId}',
    );
  }
  final questions = [...test.questions]..sort((a, b) => a.no.compareTo(b.no));
  final answers = [
    for (final question in questions)
      _scoreOf(question, selections[question.no]),
  ];
  var score = 0;
  var maxScore = 0;
  var correctCount = 0;
  var answeredCount = 0;
  for (final answer in answers) {
    score += answer.pointsEarned;
    maxScore += answer.points;
    if (answer.status == TopikAnswerStatus.correct) correctCount++;
    if (answer.status != TopikAnswerStatus.unanswered) answeredCount++;
  }
  return TopikAttemptScore(
    answers: answers,
    score: score,
    maxScore: maxScore,
    correctCount: correctCount,
    answeredCount: answeredCount,
  );
}

TopikAnswerScore _scoreOf(TopikQuestion question, int? selected) {
  final status = switch (selected) {
    null => TopikAnswerStatus.unanswered,
    final idx when idx == question.answerIdx => TopikAnswerStatus.correct,
    _ => TopikAnswerStatus.wrong,
  };
  return TopikAnswerScore(
    questionNo: question.no,
    correctIdx: question.answerIdx,
    points: question.points,
    pointsEarned: status == TopikAnswerStatus.correct ? question.points : 0,
    questionType: question.questionType,
    status: status,
  );
}
