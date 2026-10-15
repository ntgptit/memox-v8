import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_group_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

/// The supporting content a test carries, derived from its data
/// (BR-TOPIK-009).
enum TopikContentTag { explanation, translation, words, grammars, script }

/// Where a test was published (BR-TOPIK-007).
final class TopikSource {
  const TopikSource({
    required this.publishedBy,
    required this.url,
    this.publishedAt,
  });

  final String publishedBy;
  final String url;
  final String? publishedAt;
}

/// One published paper: a level, a round and a section (BR-TOPIK-001).
final class TopikTest {
  const TopikTest({
    required this.schemaVersion,
    required this.contentVersion,
    required this.testId,
    required this.level,
    required this.round,
    required this.section,
    required this.format,
    required this.form,
    required this.titleKo,
    required this.officialTimeLimitSec,
    required this.source,
    required this.groups,
    required this.questions,
    this.audioAsset,
  });

  final int schemaVersion;

  /// Goes up with every correction of this test's content (BR-TOPIK-007).
  final int contentVersion;
  final String testId;
  final TopikLevel level;
  final int round;
  final TopikSection section;
  final String format;

  /// The paper's form, such as `B-홀수형`: the answers fit this form only
  /// (BR-TOPIK-003).
  final String form;
  final String titleKo;
  final int officialTimeLimitSec;
  final TopikSource source;

  /// The section's audio file, for listening.
  final String? audioAsset;
  final List<TopikQuestionGroup> groups;

  /// Sorted by question number.
  final List<TopikQuestion> questions;

  Set<TopikContentTag> get contentTags => {
    if (questions.any((q) => q.explanation != null))
      TopikContentTag.explanation,
    if (questions.any((q) => q.translation != null) ||
        groups.any((g) => g.scriptTranslation != null))
      TopikContentTag.translation,
    if (questions.any((q) => q.words.isNotEmpty)) TopikContentTag.words,
    if (questions.any((q) => q.grammars.isNotEmpty)) TopikContentTag.grammars,
    if (groups.any((g) => g.script != null)) TopikContentTag.script,
  };
}
