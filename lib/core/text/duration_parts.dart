/// A stored duration as the screen shows it: whole hours, minutes and
/// seconds, the milliseconds truncated (BR-TOPIK-025). Hours do not wrap into
/// days. The words around the numbers are localized in `lib/l10n/`.
final class DurationParts {
  const DurationParts(this.hours, this.minutes, this.seconds);

  factory DurationParts.ofMilliseconds(int milliseconds) {
    if (milliseconds < 0) {
      throw ArgumentError.value(milliseconds, 'milliseconds', 'is negative');
    }
    final seconds = milliseconds ~/ Duration.millisecondsPerSecond;
    return DurationParts(
      seconds ~/ Duration.secondsPerHour,
      seconds % Duration.secondsPerHour ~/ Duration.secondsPerMinute,
      seconds % Duration.secondsPerMinute,
    );
  }

  final int hours;
  final int minutes;
  final int seconds;
}
