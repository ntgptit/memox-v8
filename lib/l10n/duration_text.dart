import 'package:memox/core/text/duration_parts.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// A stored duration in the person's words: `42s`, `3m 05s`, `1h 02m 11s`
/// (BR-TOPIK-025). Units after the first are zero-padded to two digits.
extension DurationText on AppLocalizations {
  String duration(int milliseconds) {
    final parts = DurationParts.ofMilliseconds(milliseconds);
    String two(int value) => value.toString().padLeft(2, '0');
    if (parts.hours > 0) {
      return commonDurationHours(
        parts.hours,
        two(parts.minutes),
        two(parts.seconds),
      );
    }
    if (parts.minutes > 0) {
      return commonDurationMinutes(parts.minutes, two(parts.seconds));
    }
    return commonDurationSeconds(parts.seconds);
  }
}
