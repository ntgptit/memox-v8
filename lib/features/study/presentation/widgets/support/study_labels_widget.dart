import 'package:intl/intl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/presentation/states/interval_span_state.dart';
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

  /// A grade's name: the card screens' action names (BR-MODE-011).
  String studyGrade(Sm2Action action) => switch (action) {
    Sm2Action.again => cardActionAgain,
    Sm2Action.hard => cardActionHard,
    Sm2Action.good => cardActionGood,
    Sm2Action.easy => cardActionEasy,
  };

  /// "6d", "2mo", "1.5y" under a grade (handoff 16a).
  String studyIntervalShort(IntervalSpan span, String localeName) =>
      switch (span) {
        DaySpan(:final days) => studyIntervalDays(days),
        MonthSpan(:final months) => studyIntervalMonths(months),
        YearSpan(:final years) => studyIntervalYears(_years(years, localeName)),
      };

  /// What TalkBack says: "6 days", "1 year" (handoff 16a).
  String studyIntervalLong(IntervalSpan span, String localeName) =>
      switch (span) {
        DaySpan(:final days) => studyIntervalDaysLong(days),
        MonthSpan(:final months) => studyIntervalMonthsLong(months),
        YearSpan(:final years) => studyIntervalYearsLong(
          _years(years, localeName),
        ),
      };

  String studyReason(ModeUnavailableReason reason) => switch (reason) {
    ModeUnavailableReason.noExample => studyEntryReasonNoExample,
    ModeUnavailableReason.tooFewPairs => studyEntryReasonTooFewPairs,
    ModeUnavailableReason.tooFewMeanings => studyEntryReasonTooFewMeanings,
  };
}

/// Years to one decimal, a trailing ".0" dropped, in the locale's decimal.
const String _yearPattern = '0.#';

String _years(double years, String localeName) =>
    NumberFormat(_yearPattern, localeName).format(years);
