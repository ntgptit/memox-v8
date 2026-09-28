import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_scheduler.dart';

void main() {
  test('runs at start, then once per debounced burst of triggers', () {
    fakeAsync((clock) {
      var runs = 0;
      final triggers = StreamController<void>();
      final scheduler = SyncScheduler(
        run: () async => runs++,
        triggers: triggers.stream,
      )..start();

      clock.elapse(Duration.zero);
      expect(runs, 1);
      triggers
        ..add(null)
        ..add(null);
      clock.elapse(const Duration(seconds: 1));
      expect(runs, 1);
      clock.elapse(const Duration(seconds: 2));
      expect(runs, 2);

      scheduler.dispose();
      triggers.close();
    });
  });

  test('a failure retries with doubling backoff capped at five minutes', () {
    fakeAsync((clock) {
      var runs = 0;
      final scheduler = SyncScheduler(
        run: () async {
          runs++;
          throw StateError('offline');
        },
        triggers: const Stream.empty(),
      )..start();

      clock.elapse(Duration.zero);
      expect(runs, 1);
      clock.elapse(const Duration(seconds: 5));
      expect(runs, 2);
      clock.elapse(const Duration(seconds: 10));
      expect(runs, 3);
      expect(scheduler.backoffFor(20), const Duration(minutes: 5));

      scheduler.dispose();
    });
  });

  test('a local write during backoff does not cut the backoff short', () {
    fakeAsync((clock) {
      var runs = 0;
      final triggers = StreamController<void>();
      final scheduler = SyncScheduler(
        run: () async {
          runs++;
          throw StateError('offline');
        },
        triggers: triggers.stream,
      )..start();

      clock.elapse(Duration.zero);
      expect(runs, 1);
      triggers.add(null);
      clock.elapse(const Duration(seconds: 3));
      expect(runs, 1, reason: 'the 5 s backoff still holds');
      clock.elapse(const Duration(seconds: 2));
      expect(runs, 2);

      scheduler.dispose();
      triggers.close();
    });
  });

  test('coming back online retries at once and resets the backoff', () {
    fakeAsync((clock) {
      var runs = 0;
      final reconnects = StreamController<void>();
      final scheduler = SyncScheduler(
        run: () async {
          runs++;
          if (runs == 1) {
            throw StateError('offline');
          }
        },
        triggers: const Stream.empty(),
        reconnects: reconnects.stream,
      )..start();

      clock.elapse(Duration.zero);
      expect(runs, 1);
      reconnects.add(null);
      clock.elapse(Duration.zero);
      expect(runs, 2);

      scheduler.dispose();
      reconnects.close();
    });
  });

  test('each run reports success or its error', () {
    fakeAsync((clock) {
      final reports = <String>[];
      var fail = true;
      final scheduler = SyncScheduler(
        run: () async {
          if (fail) throw StateError('offline');
        },
        triggers: const Stream.empty(),
        onSucceeded: () async => reports.add('ok'),
        onFailed: (error) async => reports.add('failed:$error'),
      )..start();

      clock.elapse(Duration.zero);
      fail = false;
      clock.elapse(const Duration(seconds: 5));
      expect(reports, ['failed:Bad state: offline', 'ok']);
      scheduler.dispose();
    });
  });

  test('syncNow runs at once, forgets the backoff and says how it went', () {
    fakeAsync((clock) {
      var fail = true;
      final scheduler = SyncScheduler(
        run: () async {
          if (fail) throw StateError('offline');
        },
        triggers: const Stream.empty(),
      )..start();
      clock.elapse(Duration.zero);

      bool? result;
      fail = false;
      unawaited(scheduler.syncNow().then((value) => result = value));
      clock.elapse(Duration.zero);
      expect(result, isTrue);
      scheduler.dispose();
    });
  });

  test('syncNow during a run waits for the next run', () {
    fakeAsync((clock) {
      final gate = Completer<void>();
      var runs = 0;
      final scheduler = SyncScheduler(
        run: () async {
          runs++;
          if (runs == 1) {
            await gate.future;
            throw StateError('first run fails');
          }
        },
        triggers: const Stream.empty(),
      )..start();
      clock.elapse(Duration.zero);

      bool? result;
      unawaited(scheduler.syncNow().then((value) => result = value));
      gate.complete();
      clock.elapse(Duration.zero);
      expect(runs, 2);
      expect(result, isTrue);
      scheduler.dispose();
    });
  });

  test('a report that throws does not stop the scheduler', () {
    fakeAsync((clock) {
      var runs = 0;
      final triggers = StreamController<void>();
      final scheduler = SyncScheduler(
        run: () async => runs++,
        triggers: triggers.stream,
        onSucceeded: () async => throw StateError('disk full'),
      )..start();
      clock.elapse(Duration.zero);
      triggers.add(null);
      clock.elapse(const Duration(seconds: 2));
      expect(runs, 2);
      scheduler.dispose();
      unawaited(triggers.close());
    });
  });
}
