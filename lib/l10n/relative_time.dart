import 'package:memox/l10n/generated/app_localizations.dart';

/// How long ago something happened, in the person's words: "just now",
/// "3 hours ago", "yesterday", "12 days ago", then months and years. Shared
/// by the Trash rows and the card history (DEV-170).
extension RelativeTime on AppLocalizations {
  static const int _daysPerMonth = 30;
  static const int _daysPerYear = 365;

  String ago(DateTime at, DateTime now) {
    // A time ahead of now (another device's fast clock) reads as just now.
    final ahead = now.difference(at);
    final elapsed = ahead.isNegative ? Duration.zero : ahead;
    if (elapsed.inHours < 1) return commonAgoMinutes(elapsed.inMinutes);
    if (elapsed.inDays < 1) return commonAgoHours(elapsed.inHours);
    if (elapsed.inDays == 1) return commonAgoYesterday;
    if (elapsed.inDays < _daysPerMonth) return commonAgoDays(elapsed.inDays);
    if (elapsed.inDays < _daysPerYear) {
      return commonAgoMonths(elapsed.inDays ~/ _daysPerMonth);
    }
    return commonAgoYears(elapsed.inDays ~/ _daysPerYear);
  }
}
