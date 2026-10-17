import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';

/// The Summary's question filter (BR-TOPIK-023).
enum TopikAnswerFilter { all, wrong, unanswered, correct }

/// Correct answers out of the questions of one type (BR-TOPIK-024).
final class TopikTypeStat {
  const TopikTypeStat({
    required this.type,
    required this.correct,
    required this.total,
  });

  final TopikQuestionType type;
  final int correct;
  final int total;
}

/// What Summary shows of a submitted attempt, from its snapshot alone
/// (BR-TOPIK-019, BR-TOPIK-023, BR-TOPIK-024).
final class TopikAttemptSummary {
  const TopikAttemptSummary({
    required this.score,
    required this.maxScore,
    required this.correctCount,
    required this.questionCount,
    required this.answeredCount,
    required this.accuracyPercent,
    required this.longest,
    required this.typeStats,
    required this.weakestType,
    required this.answers,
  });

  final int score;
  final int maxScore;
  final int correctCount;
  final int questionCount;
  final int answeredCount;
  final int accuracyPercent;

  /// The question that took the most time, ties to the lower number; null
  /// when no question took any time.
  final TopikAttemptAnswer? longest;

  /// One row per type in the attempt, in enum order; types this build does
  /// not know are left out.
  final List<TopikTypeStat> typeStats;
  final TopikQuestionType? weakestType;

  /// Every answer in question order.
  final List<TopikAttemptAnswer> answers;

  int get unansweredCount => questionCount - answeredCount;

  /// The time spent over all the questions, divided by the number of
  /// questions (a blank one counts in the divisor), in whole milliseconds;
  /// 0 when no question took any time.
  int get averageTimeMs {
    if (questionCount == 0) return 0;
    final total = answers.fold(0, (sum, a) => sum + a.timeSpentMs);
    return total ~/ questionCount;
  }

  List<TopikAttemptAnswer> answersFor(TopikAnswerFilter filter) {
    final wanted = switch (filter) {
      TopikAnswerFilter.all => null,
      TopikAnswerFilter.wrong => TopikAnswerStatus.wrong,
      TopikAnswerFilter.unanswered => TopikAnswerStatus.unanswered,
      TopikAnswerFilter.correct => TopikAnswerStatus.correct,
    };
    if (wanted == null) return answers;
    return [
      for (final answer in answers)
        if (answer.status == wanted) answer,
    ];
  }
}

/// A type needs this many questions to be named the weakest (BR-TOPIK-024).
const int _weakestTypeMinQuestions = 2;

TopikAttemptSummary topikAttemptSummaryOf(TopikAttemptDetail detail) {
  final attempt = detail.attempt;
  final score = attempt.score;
  final correctCount = attempt.correctCount;
  final answeredCount = attempt.answeredCount;
  if (!attempt.isCompleted ||
      score == null ||
      correctCount == null ||
      answeredCount == null) {
    throw ArgumentError.value(attempt.id, 'detail', 'is not submitted');
  }
  final answers = [...detail.answers]
    ..sort((a, b) => a.questionNo.compareTo(b.questionNo));
  final typeStats = _typeStatsOf(answers);
  return TopikAttemptSummary(
    score: score,
    maxScore: attempt.maxScore,
    correctCount: correctCount,
    questionCount: attempt.questionCount,
    answeredCount: answeredCount,
    accuracyPercent:
        (2 * correctCount * 100 + attempt.questionCount) ~/
        (2 * attempt.questionCount),
    longest: _longestOf(answers),
    typeStats: typeStats,
    weakestType: _weakestOf(typeStats),
    answers: answers,
  );
}

TopikAttemptAnswer? _longestOf(List<TopikAttemptAnswer> byNumber) {
  TopikAttemptAnswer? longest;
  for (final answer in byNumber) {
    if (answer.timeSpentMs <= (longest?.timeSpentMs ?? 0)) continue;
    longest = answer;
  }
  return longest;
}

List<TopikTypeStat> _typeStatsOf(List<TopikAttemptAnswer> answers) {
  final correct = <TopikQuestionType, int>{};
  final total = <TopikQuestionType, int>{};
  for (final answer in answers) {
    final type = answer.questionType;
    if (type == null) continue;
    total[type] = (total[type] ?? 0) + 1;
    if (answer.status == TopikAnswerStatus.correct) {
      correct[type] = (correct[type] ?? 0) + 1;
    }
  }
  return [
    for (final type in TopikQuestionType.values)
      if (total.containsKey(type))
        TopikTypeStat(
          type: type,
          correct: correct[type] ?? 0,
          total: total[type]!,
        ),
  ];
}

TopikQuestionType? _weakestOf(List<TopikTypeStat> stats) {
  TopikTypeStat? weakest;
  for (final stat in stats) {
    if (stat.total < _weakestTypeMinQuestions) continue;
    if (stat.correct == stat.total) continue;
    if (weakest == null || _isWeaker(stat, weakest)) weakest = stat;
  }
  return weakest?.type;
}

/// Lower accuracy first, then more questions; [stats] come in enum order, so
/// an exact tie keeps the earlier type.
bool _isWeaker(TopikTypeStat a, TopikTypeStat b) {
  final left = a.correct * b.total;
  final right = b.correct * a.total;
  if (left != right) return left < right;
  return a.total > b.total;
}
