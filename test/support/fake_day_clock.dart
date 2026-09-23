import 'dart:async';

import 'package:memox/core/clock/day_clock.dart';

/// A day clock a test moves by hand: [startDay] is midnight arriving.
final class FakeDayClock implements DayClock {
  FakeDayClock(this.current);

  DateTime current;
  final _starts = StreamController<DateTime>.broadcast();

  @override
  DateTime now() => current;

  @override
  Stream<DateTime> dayStarts() => _starts.stream;

  void startDay(DateTime day) {
    current = day;
    _starts.add(day);
  }
}
