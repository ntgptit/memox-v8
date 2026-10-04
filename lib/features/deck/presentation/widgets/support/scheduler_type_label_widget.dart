import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The name a person reads for each scheduler.
extension SchedulerTypeLabel on AppLocalizations {
  String schedulerType(SchedulerType type) => switch (type) {
    SchedulerType.eightBox => deckSchedulerEightBox,
    SchedulerType.sm2 => deckSchedulerSm2,
  };
}
