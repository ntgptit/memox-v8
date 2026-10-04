import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Plain copy for every reason the scheduler refuses a write (spec §5).
extension SrsRejectionMessage on AppLocalizations {
  String srsRejection(SrsRejection reason) => switch (reason) {
    SrsRejection.unsupportedAction => srsRejectionUnsupportedAction,
    SrsRejection.schedulerLocked => srsRejectionSchedulerLocked,
    SrsRejection.staleGeneration => srsRejectionStaleGeneration,
    SrsRejection.notFound => srsRejectionNotFound,
    SrsRejection.notARootDeck => srsRejectionNotARootDeck,
  };
}
