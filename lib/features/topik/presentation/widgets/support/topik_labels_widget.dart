import 'package:intl/intl.dart';
import 'package:memox/l10n/meta_line.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_text_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The TOPIK screens' words for domain values (spec §8).
extension TopikLabels on AppLocalizations {
  String topikLevelName(TopikLevel level) => switch (level) {
    TopikLevel.topik1 => topikLevel1,
    TopikLevel.topik2 => topikLevel2,
  };

  /// The grades a level covers; with [topikBothSections] it is what the
  /// level covers, as two terms of a meta line.
  String topikLevelGrades(TopikLevel level) => switch (level) {
    TopikLevel.topik1 => topikLevel1Grades,
    TopikLevel.topik2 => topikLevel2Grades,
  };

  String topikSectionName(TopikSection section) => switch (section) {
    TopikSection.reading => topikReading,
    TopikSection.listening => topikListening,
  };

  String topikTagName(TopikContentTag tag) => switch (tag) {
    TopikContentTag.explanation => topikTagExplanation,
    TopikContentTag.translation => topikTagTranslation,
    TopikContentTag.words => topikTagWords,
    TopikContentTag.grammars => topikTagGrammar,
    TopikContentTag.script => topikTagScript,
  };

  String topikOrderName(TopikTestOrder order) => switch (order) {
    TopikTestOrder.roundDescending => topikOrderNewest,
    TopikTestOrder.roundAscending => topikOrderOldest,
    TopikTestOrder.latestActivity => topikOrderRecent,
  };

  /// A test's status on its row (BR-TOPIK-022): in progress first, then the
  /// best score with the completed count.
  String topikTestStatusLine(TopikTestStatus? status) {
    final best = status?.bestScore;
    final parts = [
      if (status != null && status.hasInProgress) topikStatusInProgress,
      if (status != null && best != null) ...[
        topikStatusBest(best),
        topikAttemptCount(status.completedCount),
      ],
    ];
    return parts.isEmpty ? topikStatusNotStarted : metaTerms(parts);
  }

  String topikRejectionMessage(TopikRejection reason) => switch (reason) {
    TopikRejection.testUnavailable => topikTestMissingTitle,
    TopikRejection.notFound => topikAttemptMissing,
    TopikRejection.inProgressExists => topikContinueTitle,
    TopikRejection.attemptCompleted ||
    TopikRejection.unknownQuestion ||
    TopikRejection.invalidOption ||
    TopikRejection.contentMismatch => topikRefused,
  };

  /// "Oct 15, 09:30" in the UI language, local time.
  String topikDateTime(DateTime at) =>
      DateFormat.MMMd(localeName).add_Hm().format(at.toLocal());

  /// A playback speed with no trailing zero, in the UI language: "1",
  /// "0.75" ("0,75" in Vietnamese).
  String topikSpeedText(double speed) =>
      NumberFormat('0.##', localeName).format(speed);

  /// A translation of the content in the UI language (Korean is never
  /// translated: this is the content's own vi or en text).
  String topikText(TopikText text) =>
      localeName.startsWith('vi') ? text.vi : text.en;

  /// A question type's short name (screen 38's By question type).
  String topikTypeName(TopikQuestionType type) => switch (type) {
    TopikQuestionType.l1AnswerQuestion => topikTypeAnswerQuestion,
    TopikQuestionType.l1NextUtterance ||
    TopikQuestionType.l2NextUtterance => topikTypeNextUtterance,
    TopikQuestionType.l1Place => topikTypePlace,
    TopikQuestionType.l1Topic || TopikQuestionType.r1Topic => topikTypeTopic,
    TopikQuestionType.l1Picture => topikTypePicture,
    TopikQuestionType.l1MatchContent ||
    TopikQuestionType.r1MatchContent ||
    TopikQuestionType.l2MatchContent ||
    TopikQuestionType.r2MatchContent => topikTypeSameContent,
    TopikQuestionType.l1MainIdea ||
    TopikQuestionType.r1MainIdea ||
    TopikQuestionType.l2MainIdea => topikTypeMainIdea,
    TopikQuestionType.l1Paired ||
    TopikQuestionType.r1Paired ||
    TopikQuestionType.l2Paired ||
    TopikQuestionType.r2Paired => topikTypePaired,
    TopikQuestionType.r1FillBlank => topikTypeFillBlank,
    TopikQuestionType.r1NotMatch => topikTypeNotSame,
    TopikQuestionType.r1Ordering ||
    TopikQuestionType.r2Ordering => topikTypeOrdering,
    TopikQuestionType.r1LongPaired ||
    TopikQuestionType.r2LongPaired => topikTypeLongPassage,
    TopikQuestionType.l2PictureGraph => topikTypePictureGraph,
    TopikQuestionType.l2NextAction => topikTypeNextAction,
    TopikQuestionType.l2PairedAdvanced => topikTypePairedAdvanced,
    TopikQuestionType.r2GrammarBlank => topikTypeGrammarBlank,
    TopikQuestionType.r2SimilarExpression => topikTypeSimilarExpression,
    TopikQuestionType.r2AdTopic => topikTypeAdTopic,
    TopikQuestionType.r2ParagraphBlank => topikTypeParagraphBlank,
    TopikQuestionType.r2Headline => topikTypeHeadline,
    TopikQuestionType.r2ComplexBlank => topikTypeComplexBlank,
    TopikQuestionType.r2MatchContentMid => topikTypeSameContentMid,
    TopikQuestionType.r2Theme => topikTypeTheme,
    TopikQuestionType.r2SentenceInsert => topikTypeSentenceInsert,
  };

  String topikFilterName(TopikAnswerFilter filter) => switch (filter) {
    TopikAnswerFilter.all => topikFilterAll,
    TopikAnswerFilter.wrong => topikWrong,
    TopikAnswerFilter.unanswered => topikUnanswered,
    TopikAnswerFilter.correct => topikCorrect,
  };

  String topikAnswerStatusName(TopikAnswerStatus status) => switch (status) {
    TopikAnswerStatus.correct => topikCorrect,
    TopikAnswerStatus.wrong => topikWrong,
    TopikAnswerStatus.unanswered => topikUnanswered,
  };

  /// What a filter with no question says (screen 38's filterEmpty).
  String topikFilterEmpty(TopikAnswerFilter filter) => switch (filter) {
    TopikAnswerFilter.wrong => topikNoWrong,
    TopikAnswerFilter.unanswered => topikNoUnanswered,
    TopikAnswerFilter.correct || TopikAnswerFilter.all => topikNoCorrect,
  };
}

/// An answer's meta line on screens 38 and 39: what the person chose, the
/// right option unless [right] is null, and the [time] when given.
/// [shown] writes the options as ①–④ and glues its terms (The Wrap Rule);
/// [spoken] writes them as plain digits for a screen reader, which reads
/// "③" as a symbol name (owner 2026-10-17).
extension TopikAnswerMeta on AppLocalizations {
  ({String shown, String spoken}) topikAnswerMeta({
    required int? selected,
    required int? right,
    String? time,
  }) {
    List<String> terms(String Function(int) option) => [
      if (selected == null)
        topikNotAnswered
      else
        topikYourAnswer(option(selected)),
      if (right != null) topikRightAnswer(option(right)),
      ?time,
    ];
    return (
      shown: metaTerms(terms(topikCircled)),
      spoken: terms((idx) => '$idx').join(', '),
    );
  }
}

/// An audio position as minutes and seconds, "1:33" (spec §5.5); the
/// seconds are cut, not rounded, so the clock never runs ahead.
String topikClockText(int ms) {
  final seconds = ms ~/ Duration.millisecondsPerSecond;
  final minutes = seconds ~/ Duration.secondsPerMinute;
  final rest = seconds % Duration.secondsPerMinute;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

/// "①" to "④", the option numbers of the paper (spec §6.4).
String topikCircled(int idx) => String.fromCharCode(_circledZero + idx);

/// The code point before "①".
const int _circledZero = 0x245F;
