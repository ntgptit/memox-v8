import 'package:memox/features/progress/domain/models/progress_level_model.dart';

/// The local days of one read (BR-PROGRESS-011, BR-PROGRESS-013; Progress
/// spec §5.1). An answer falls on the day its UTC time has at [utcOffset], the
/// offset of this read, however old it is: `review_log` keeps no offset.
final class ProgressDays {
  const ProgressDays._({required this.today, required this.utcOffset});

  /// One snapshot of the clock and its offset; nothing reads either again.
  factory ProgressDays.of(DateTime now, Duration utcOffset) {
    final seconds =
        now.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
    return ProgressDays._(
      today: (seconds + utcOffset.inSeconds) ~/ Duration.secondsPerDay,
      utcOffset: utcOffset,
    );
  }

  /// Today, as days since 1970-01-01 at [utcOffset].
  final int today;

  final Duration utcOffset;

  /// The first day of the last seven, today being the seventh
  /// (BR-PROGRESS-003, BR-PROGRESS-015).
  int get weekStart => _startOf(ProgressRange.week);

  /// The first day of the last thirty (BR-PROGRESS-003).
  int get monthStart => _startOf(ProgressRange.month);

  /// The next local midnight, an instant: every number of the snapshot
  /// changes there with no write (BR-PROGRESS-003).
  DateTime get validUntil => DateTime.fromMillisecondsSinceEpoch(
    ((today + 1) * Duration.secondsPerDay - utcOffset.inSeconds) *
        Duration.millisecondsPerSecond,
    isUtc: true,
  );

  /// The calendar date of [day], for a day's label and the lost streak's
  /// note.
  DateTime dateOf(int day) {
    final date = DateTime.utc(1970, 1, 1 + day);
    return DateTime(date.year, date.month, date.day);
  }

  int _startOf(ProgressRange range) => today - range.days + 1;
}
