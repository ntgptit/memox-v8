import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The study screens' names for the domain's modes, schedulers and reasons.
extension StudyLabels on AppLocalizations {
  String studyMode(StudyMode mode) => switch (mode) {
    StudyMode.browse => cardModeBrowse,
    StudyMode.selfAssess => cardModeSelfAssess,
    StudyMode.match => cardModeMatch,
    StudyMode.guess => cardModeGuess,
    StudyMode.recall => cardModeRecall,
    StudyMode.fill => cardModeFill,
  };

  /// The entry's one-line description of a review mode; null for a mode
  /// the entry never lists as a choice (BR-STUDY-055).
  String? studyModeBody(StudyMode mode) => switch (mode) {
    StudyMode.match => studyEntryModeMatchBody,
    StudyMode.guess => studyEntryModeGuessBody,
    StudyMode.recall => studyEntryModeRecallBody,
    StudyMode.fill => studyEntryModeFillBody,
    StudyMode.browse || StudyMode.selfAssess => null,
  };

  String studyScheduler(SchedulerType type) => switch (type) {
    SchedulerType.eightBox => deckSchedulerEightBox,
    SchedulerType.sm2 => deckSchedulerSm2,
  };

  /// The Learn row's stage line (BR-STUDY-056).
  String studyLearnStages(SchedulerType type) => switch (type) {
    SchedulerType.eightBox => studyEntryLearnStagesEightBox,
    SchedulerType.sm2 => studyEntryLearnStagesSm2,
  };

  String studyReason(ModeUnavailableReason reason) => switch (reason) {
    ModeUnavailableReason.noExample => studyEntryReasonNoExample,
    ModeUnavailableReason.tooFewPairs => studyEntryReasonTooFewPairs,
    ModeUnavailableReason.tooFewMeanings => studyEntryReasonTooFewMeanings,
  };
}
