/// How far back the Time filter reaches (monitoring spec §3.2). The window is
/// relative, so the same filter asked again a minute later reaches a minute
/// further.
enum LogWindow {
  hour(Duration(hours: 1)),
  day(Duration(hours: 24)),
  week(Duration(days: 7)),
  month(Duration(days: 30)),
  all(null);

  const LogWindow(this.span);

  /// Null reaches back without limit.
  final Duration? span;

  /// The earliest time a log may have happened at, or null for [all].
  DateTime? since(DateTime now) {
    final reach = span;
    return reach == null ? null : now.subtract(reach);
  }
}
