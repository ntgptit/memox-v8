import 'package:memox/l10n/generated/app_localizations.dart';

/// The one place a bulk action's toast gains "N were already gone" (SP2a
/// 2.19), for every action and both features.
extension BulkMessage on AppLocalizations {
  String bulkToast(String message, int skipped) =>
      skipped == 0 ? message : cardBulkWithSkipped(message, skipped);
}
