import 'dart:async';

/// The app's "now" and its local days (BR-STUDY-067, BR-STUDY-068). An
/// interface because tests drive days by hand — the reason ADR-010 accepts.
abstract interface class DayClock {
  DateTime now();

  /// The start of each new local day, from the next midnight on.
  Stream<DateTime> dayStarts();
}

final class SystemDayClock implements DayClock {
  const SystemDayClock({this._now = DateTime.now});

  final DateTime Function() _now;

  @override
  DateTime now() => _now();

  /// One timer per listener, re-armed after each midnight. The next midnight
  /// is counted from the one just emitted, so a timer that fires a little
  /// early never emits the same day twice.
  @override
  Stream<DateTime> dayStarts() {
    Timer? timer;
    late final StreamController<DateTime> controller;

    void armFor(DateTime midnight) {
      timer = Timer(midnight.difference(_now()), () {
        controller.add(midnight);
        armFor(DateTime(midnight.year, midnight.month, midnight.day + 1));
      });
    }

    controller = StreamController<DateTime>(
      onListen: () {
        final now = _now();
        armFor(DateTime(now.year, now.month, now.day + 1));
      },
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }
}

/// [watch] for the current local day, started again at each new day with
/// that day's start as `now`. A read model whose sets depend on the day (Due,
/// Overdue) so changes at midnight with no database write (BR-STUDY-067,
/// BR-STUDY-068); `due_at` always falls on a local midnight (BR-STUDY-074),
/// so a day's start is as good a `now` as any instant of that day.
Stream<T> watchEachLocalDay<T>(
  DayClock clock,
  Stream<T> Function(DateTime now) watch,
) {
  StreamSubscription<T>? current;
  StreamSubscription<DateTime>? days;
  late final StreamController<T> controller;

  void follow(DateTime now) {
    current?.cancel();
    current = watch(now).listen(controller.add, onError: controller.addError);
  }

  controller = StreamController<T>(
    onListen: () {
      follow(clock.now());
      days = clock.dayStarts().listen(follow);
    },
    onCancel: () async {
      await days?.cancel();
      await current?.cancel();
    },
  );
  return controller.stream;
}
