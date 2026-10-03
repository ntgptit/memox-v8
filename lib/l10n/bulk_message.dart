import 'package:memox/l10n/generated/app_localizations.dart';

/// The one place a bulk action's toast gains "N were already gone" (SP2a
/// 2.19), for every action and both features. A message that already ends
/// in a period (the export's) gives it up to the sentence that follows, so
/// the toast never reads "..".
extension BulkMessage on AppLocalizations {
  static const _period = '.';

  String bulkToast(String message, int skipped) => skipped == 0
      ? message
      : cardBulkWithSkipped(
          message.endsWith(_period)
              ? message.substring(0, message.length - _period.length)
              : message,
          skipped,
        );
}
