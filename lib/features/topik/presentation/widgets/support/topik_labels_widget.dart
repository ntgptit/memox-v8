import 'package:intl/intl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

const String _nonBreakingSpace = '\u00A0';
const String _wordJoiner = '\u2060';

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
    return parts.isEmpty ? topikStatusNotStarted : topikTerms(parts);
  }

  /// [terms] as one meta line that wraps only between whole terms (The Wrap
  /// Rule): a term's own spaces and range dashes ("Levels 1–2") do not
  /// break, and each dot stays with the term before it, as
  /// `MxWorkloadBreakdownLine` glues its terms.
  String topikTerms(Iterable<String> terms) => [
    for (final term in terms)
      term
          .replaceAll(' ', _nonBreakingSpace)
          .replaceAll('–', '$_wordJoiner–$_wordJoiner'),
  ].join('$_nonBreakingSpace· ');

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
