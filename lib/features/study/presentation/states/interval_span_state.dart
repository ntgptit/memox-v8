/// How a next interval reads on a grade (handoff 16a).
sealed class IntervalSpan {
  const IntervalSpan();
}

final class DaySpan extends IntervalSpan {
  const DaySpan(this.days);

  final int days;

  @override
  bool operator ==(Object other) => other is DaySpan && other.days == days;

  @override
  int get hashCode => days.hashCode;
}

final class MonthSpan extends IntervalSpan {
  const MonthSpan(this.months);

  final int months;

  @override
  bool operator ==(Object other) =>
      other is MonthSpan && other.months == months;

  @override
  int get hashCode => months.hashCode;
}

/// Whole and part years alike, to one decimal.
final class YearSpan extends IntervalSpan {
  const YearSpan(this.years);

  final double years;

  @override
  bool operator ==(Object other) => other is YearSpan && other.years == years;

  @override
  int get hashCode => years.hashCode;
}

const int _daysInMonth = 30;
const int _daysInYear = 365;
const int _tenths = 10;

/// Under 30 days in days; under a year in months, days / 30 rounded; from a
/// year in years to one decimal (handoff 16a).
IntervalSpan intervalSpanOf(int days) {
  if (days < _daysInMonth) return DaySpan(days);
  if (days < _daysInYear) return MonthSpan((days / _daysInMonth).round());
  return YearSpan((days * _tenths / _daysInYear).round() / _tenths);
}
