import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/day_clock.dart';

import '../../support/fake_day_clock.dart';

void main() {
  test('SystemDayClock emits each local midnight, once', () {
    fakeAsync((async) {
      final time = async.getClock(DateTime(2026, 9, 23, 22, 30));
      final starts = <DateTime>[];
      SystemDayClock(now: time.now).dayStarts().listen(starts.add);

      async.elapse(const Duration(hours: 1, minutes: 29));
      expect(starts, isEmpty);
      async.elapse(const Duration(minutes: 2));
      expect(starts, [DateTime(2026, 9, 24)]);
      async.elapse(const Duration(days: 1));
      expect(starts, [DateTime(2026, 9, 24), DateTime(2026, 9, 25)]);
    });
  });

  test('watchEachLocalDay restarts the watch with the new day', () async {
    final clock = FakeDayClock(DateTime(2026, 9, 23, 10));
    final watched = <DateTime>[];
    final values = <String>[];
    final subscription = watchEachLocalDay(clock, (now) {
      watched.add(now);
      return Stream.value('day ${now.day}');
    }).listen(values.add);
    await pumpEventQueue();

    clock.startDay(DateTime(2026, 9, 24));
    await pumpEventQueue();

    expect(watched, [DateTime(2026, 9, 23, 10), DateTime(2026, 9, 24)]);
    expect(values, ['day 23', 'day 24']);
    await subscription.cancel();
  });

  test('watchEachLocalDay stops the previous day watch', () async {
    final clock = FakeDayClock(DateTime(2026, 9, 23, 10));
    final firstDay = StreamController<String>();
    final values = <String>[];
    final subscription = watchEachLocalDay(
      clock,
      (now) => now.day == 23 ? firstDay.stream : const Stream<String>.empty(),
    ).listen(values.add);
    await pumpEventQueue();

    clock.startDay(DateTime(2026, 9, 24));
    await pumpEventQueue();

    expect(firstDay.hasListener, isFalse);
    await subscription.cancel();
  });
}
