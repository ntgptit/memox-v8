import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

/// The kind of a question (BR-TOPIK-005), with the question numbers it
/// usually covers on the published PBT papers 35–102. The range is a default,
/// not a rule: a question outside it is a warning, never a rejection.
enum TopikQuestionType {
  l1AnswerQuestion(
    'L1_answer_question',
    TopikLevel.topik1,
    TopikSection.listening,
    1,
    4,
  ),
  l1NextUtterance(
    'L1_next_utterance',
    TopikLevel.topik1,
    TopikSection.listening,
    5,
    6,
  ),
  l1Place('L1_place', TopikLevel.topik1, TopikSection.listening, 7, 10),
  l1Topic('L1_topic', TopikLevel.topik1, TopikSection.listening, 11, 14),
  l1Picture('L1_picture', TopikLevel.topik1, TopikSection.listening, 15, 16),
  l1MatchContent(
    'L1_match_content',
    TopikLevel.topik1,
    TopikSection.listening,
    17,
    21,
  ),
  l1MainIdea('L1_main_idea', TopikLevel.topik1, TopikSection.listening, 22, 24),
  l1Paired('L1_paired', TopikLevel.topik1, TopikSection.listening, 25, 30),
  r1Topic('R1_topic', TopikLevel.topik1, TopikSection.reading, 31, 33),
  r1FillBlank('R1_fill_blank', TopikLevel.topik1, TopikSection.reading, 34, 39),
  r1NotMatch('R1_not_match', TopikLevel.topik1, TopikSection.reading, 40, 42),
  r1MatchContent(
    'R1_match_content',
    TopikLevel.topik1,
    TopikSection.reading,
    43,
    45,
  ),
  r1MainIdea('R1_main_idea', TopikLevel.topik1, TopikSection.reading, 46, 48),
  r1Paired('R1_paired', TopikLevel.topik1, TopikSection.reading, 49, 56),
  r1Ordering('R1_ordering', TopikLevel.topik1, TopikSection.reading, 57, 58),
  r1LongPaired(
    'R1_long_paired',
    TopikLevel.topik1,
    TopikSection.reading,
    59,
    70,
  ),
  l2PictureGraph(
    'L2_picture_graph',
    TopikLevel.topik2,
    TopikSection.listening,
    1,
    3,
  ),
  l2NextUtterance(
    'L2_next_utterance',
    TopikLevel.topik2,
    TopikSection.listening,
    4,
    8,
  ),
  l2NextAction(
    'L2_next_action',
    TopikLevel.topik2,
    TopikSection.listening,
    9,
    12,
  ),
  l2MatchContent(
    'L2_match_content',
    TopikLevel.topik2,
    TopikSection.listening,
    13,
    16,
  ),
  l2MainIdea('L2_main_idea', TopikLevel.topik2, TopikSection.listening, 17, 20),
  l2Paired('L2_paired', TopikLevel.topik2, TopikSection.listening, 21, 36),
  l2PairedAdvanced(
    'L2_paired_advanced',
    TopikLevel.topik2,
    TopikSection.listening,
    37,
    50,
  ),
  r2GrammarBlank(
    'R2_grammar_blank',
    TopikLevel.topik2,
    TopikSection.reading,
    1,
    2,
  ),
  r2SimilarExpression(
    'R2_similar_expression',
    TopikLevel.topik2,
    TopikSection.reading,
    3,
    4,
  ),
  r2AdTopic('R2_ad_topic', TopikLevel.topik2, TopikSection.reading, 5, 8),
  r2MatchContent(
    'R2_match_content',
    TopikLevel.topik2,
    TopikSection.reading,
    9,
    12,
  ),
  r2Ordering('R2_ordering', TopikLevel.topik2, TopikSection.reading, 13, 15),
  r2ParagraphBlank(
    'R2_paragraph_blank',
    TopikLevel.topik2,
    TopikSection.reading,
    16,
    18,
  ),
  r2Paired('R2_paired', TopikLevel.topik2, TopikSection.reading, 19, 24),
  r2Headline('R2_headline', TopikLevel.topik2, TopikSection.reading, 25, 27),
  r2ComplexBlank(
    'R2_complex_blank',
    TopikLevel.topik2,
    TopikSection.reading,
    28,
    31,
  ),
  r2MatchContentMid(
    'R2_match_content_mid',
    TopikLevel.topik2,
    TopikSection.reading,
    32,
    34,
  ),
  r2Theme('R2_theme', TopikLevel.topik2, TopikSection.reading, 35, 38),
  r2SentenceInsert(
    'R2_sentence_insert',
    TopikLevel.topik2,
    TopikSection.reading,
    39,
    41,
  ),
  r2LongPaired(
    'R2_long_paired',
    TopikLevel.topik2,
    TopikSection.reading,
    42,
    50,
  );

  const TopikQuestionType(
    this.code,
    this.level,
    this.section,
    this.defaultFirstNo,
    this.defaultLastNo,
  );

  /// The value stored in content files and answer snapshots.
  final String code;
  final TopikLevel level;
  final TopikSection section;
  final int defaultFirstNo;
  final int defaultLastNo;

  static TopikQuestionType? ofCode(Object? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }

  /// The type question [questionNo] usually has, or null outside the layout.
  static TopikQuestionType? defaultFor(
    TopikLevel level,
    TopikSection section,
    int questionNo,
  ) {
    for (final type in values) {
      if (type.level != level || type.section != section) continue;
      if (questionNo < type.defaultFirstNo) continue;
      if (questionNo > type.defaultLastNo) continue;
      return type;
    }
    return null;
  }
}
