/// Local midnight [daysFromNow] days after [now]'s local date. Time-of-day
/// on [now] is discarded: a review at 23:59 due "tomorrow" is due at
/// tomorrow's midnight, not 24h later.
///
/// Counts calendar days, never `Duration(days: n)`: across a daylight-saving
/// change, `n * 24h` lands on 23:00 or 01:00 instead of midnight
/// (BR-STUDY-074).
DateTime dueAtLocalMidnight(DateTime now, int daysFromNow) =>
    DateTime(now.year, now.month, now.day + daysFromNow);
