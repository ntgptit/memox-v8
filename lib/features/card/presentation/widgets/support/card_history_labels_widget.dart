import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The stored codes of a card's schedule and history, in the person's words.
extension CardHistoryLabels on AppLocalizations {
  String cardScheduler(SchedulerType type) => switch (type) {
    SchedulerType.eightBox => cardSchedulerEightBox,
    SchedulerType.sm2 => cardSchedulerSm2,
  };

  /// BR-CARD-016: the kind as stored, never inferred.
  String cardHistoryKind(ReviewKind kind) => switch (kind) {
    ReviewKind.learning => cardHistoryKindLearning,
    ReviewKind.scheduled => cardHistoryKindScheduled,
    ReviewKind.relearning => cardHistoryKindRelearning,
  };

  /// An `EightBoxAction` or a `Sm2Action`, after the entry's scheduler.
  String cardHistoryAction(Enum action) => switch (action) {
    EightBoxAction.forgotten => cardActionForgotten,
    EightBoxAction.remembered => cardActionRemembered,
    Sm2Action.again => cardActionAgain,
    Sm2Action.hard => cardActionHard,
    Sm2Action.good => cardActionGood,
    Sm2Action.easy => cardActionEasy,
    _ => action.name,
  };

  /// Ruling P4b-L9: the study feature owns the modes; a code this list does
  /// not know shows as stored.
  String cardHistoryMode(String mode) => switch (mode) {
    'browse' => cardModeBrowse,
    'self_assess' => cardModeSelfAssess,
    'match' => cardModeMatch,
    'guess' => cardModeGuess,
    'recall' => cardModeRecall,
    'fill' => cardModeFill,
    _ => mode,
  };
}
