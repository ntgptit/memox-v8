import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_text_model.dart';

/// One of a question's four choices, numbered 1–4 like ①–④ (BR-TOPIK-003).
/// The option numbers of every question, ①–④ (BR-TOPIK-003). The schema's
/// `selected_idx` and `correct_idx` CHECKs copy this range.
const Set<int> topikOptionIdxs = {1, 2, 3, 4};

final class TopikOption {
  const TopikOption({required this.idx, this.textKo, this.image});

  final int idx;
  final String? textKo;

  /// An asset path, for picture questions.
  final String? image;
}

/// A word of the question with its meaning.
final class TopikWord {
  const TopikWord({required this.ko, required this.meaning, this.pos});

  final String ko;
  final TopikText meaning;

  /// Part of speech as the content writes it (`n`, `v`, …).
  final String? pos;
}

/// A grammar pattern of the question with its meaning.
final class TopikGrammar {
  const TopikGrammar({required this.pattern, required this.meaning});

  final String pattern;
  final TopikText meaning;
}

/// One question with its real number (BR-TOPIK-001) and official points
/// (BR-TOPIK-002).
final class TopikQuestion {
  const TopikQuestion({
    required this.no,
    required this.groupId,
    required this.questionType,
    required this.points,
    required this.stemKo,
    required this.options,
    required this.answerIdx,
    this.explanation,
    this.translation,
    this.words = const [],
    this.grammars = const [],
  });

  final int no;
  final String groupId;
  final TopikQuestionType questionType;
  final int points;
  final String stemKo;
  final List<TopikOption> options;
  final int answerIdx;
  final TopikText? explanation;
  final TopikText? translation;
  final List<TopikWord> words;
  final List<TopikGrammar> grammars;
}
