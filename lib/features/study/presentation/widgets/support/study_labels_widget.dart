import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The study feature's codes, in the person's words.
extension StudyLabels on AppLocalizations {
  String studyScheduler(SchedulerType type) => switch (type) {
    SchedulerType.eightBox => deckSchedulerEightBox,
    SchedulerType.sm2 => deckSchedulerSm2,
  };

  String studySessionKind(SessionKind kind) => switch (kind) {
    SessionKind.learning => studySessionKindLearning,
    SessionKind.reviewing => studySessionKindReviewing,
  };

  String studyMode(StudyMode mode) => switch (mode) {
    StudyMode.browse => cardModeBrowse,
    StudyMode.selfAssess => cardModeSelfAssess,
    StudyMode.match => cardModeMatch,
    StudyMode.guess => cardModeGuess,
    StudyMode.recall => cardModeRecall,
    StudyMode.fill => cardModeFill,
  };

  /// A refused study action: the session is over, the deck is gone, or the
  /// action no longer fits.
  String studyRejection(StudyRejection reason) => switch (reason) {
    StudyRejection.sessionClosed ||
    StudyRejection.sessionExpired ||
    StudyRejection.staleGeneration => studyRejectionEnded,
    StudyRejection.notFound => studyRejectionGone,
    _ => studyRejectionOther,
  };
}
