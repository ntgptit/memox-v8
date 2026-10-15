import 'package:intl/intl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The TOPIK screens' words for domain values (spec §8).
extension TopikLabels on AppLocalizations {
  String topikLevelName(TopikLevel level) => switch (level) {
    TopikLevel.topik1 => topikLevel1,
    TopikLevel.topik2 => topikLevel2,
  };

  String topikLevelScope(TopikLevel level) => switch (level) {
    TopikLevel.topik1 => topikLevel1Scope,
    TopikLevel.topik2 => topikLevel2Scope,
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
    return parts.isEmpty ? topikStatusNotStarted : parts.join(' · ');
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
}
