import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_scheduler.dart';

import '../../support/recording_log_sink.dart';

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

  test('a success that cannot be recorded counts as a failed run', () {
    fakeAsync((clock) {
      var runs = 0;
      var recordFails = true;
      final scheduler = SyncScheduler(
        run: () async => runs++,
        triggers: const Stream.empty(),
        onSucceeded: () async {
          if (recordFails) throw StateError('disk full');
        },
      )..start();

      bool? result;
      clock.elapse(Duration.zero);
      expect(runs, 1);
      unawaited(scheduler.syncNow().then((value) => result = value));
      recordFails = false;
      clock.elapse(Duration.zero);
      expect(runs, 2);
      expect(result, isTrue);
      scheduler.dispose();
    });
  });

  test('an unrecordable success backs off and retries (spec §6)', () {
    fakeAsync((clock) {
      var runs = 0;
      final scheduler = SyncScheduler(
        run: () async => runs++,
        triggers: const Stream.empty(),
        onSucceeded: () async => throw StateError('disk full'),
      )..start();

      clock.elapse(Duration.zero);
      expect(runs, 1);
      clock.elapse(const Duration(seconds: 5));
      expect(runs, 2);
      scheduler.dispose();
    });
  });

  test('a failure that cannot be recorded still backs off', () {
    fakeAsync((clock) {
      var runs = 0;
      final scheduler = SyncScheduler(
        run: () async {
          runs++;
          throw StateError('offline');
        },
        triggers: const Stream.empty(),
        onFailed: (_) async => throw StateError('disk full'),
      )..start();

      clock.elapse(Duration.zero);
      clock.elapse(const Duration(seconds: 5));
      expect(runs, 2);
      scheduler.dispose();
    });
  });

  test('a run that fails offline is logged at info, any other failure as an '
      'error (ADR-018: offline is a normal state, not an open error)', () {
    fakeAsync((clock) {
      final sink = RecordingLogSink();
      Object failure = const SocketException('offline');
      final scheduler = SyncScheduler(
        run: () async => throw failure,
        triggers: const Stream.empty(),
        logger: AppLogger(sinks: [sink]),
      )..start();

      clock.elapse(Duration.zero);
      failure = StateError('bug');
      scheduler.syncNow();
      clock.elapse(Duration.zero);

      expect(
        [for (final e in sink.entries) (e.event, e.level)],
        [('sync.failed', LogLevel.info), ('sync.failed', LogLevel.error)],
      );
      scheduler.dispose();
    });
  });

  test('started paused, nothing runs until resume', () {
    fakeAsync((clock) {
      var runs = 0;
      final triggers = StreamController<void>();
      final reconnects = StreamController<void>();
      final scheduler = SyncScheduler(
        run: () async => runs++,
        triggers: triggers.stream,
        reconnects: reconnects.stream,
      )..start(paused: true);

      triggers.add(null);
      reconnects.add(null);
      clock.elapse(const Duration(minutes: 1));
      expect(runs, 0);
      expect(scheduler.isPaused, isTrue);

      var answered = false;
      scheduler.syncNow().then((ok) {
        expect(ok, isFalse);
        answered = true;
      });
      clock.flushMicrotasks();
      expect(answered, isTrue);
      expect(runs, 0);

      scheduler.resume();
      clock.elapse(Duration.zero);
      expect(runs, 1);

      scheduler.dispose();
      triggers.close();
      reconnects.close();
    });
  });

  test('pause waits for the run in progress and schedules nothing after', () {
    fakeAsync((clock) {
      var runs = 0;
      final release = Completer<void>();
      final triggers = StreamController<void>();
      final scheduler = SyncScheduler(
        run: () async {
          runs++;
          await release.future;
        },
        triggers: triggers.stream,
      )..start();
      clock.elapse(Duration.zero);
      expect(runs, 1);

      var paused = false;
      scheduler.pause().then((_) => paused = true);
      clock.flushMicrotasks();
      expect(paused, isFalse);

      triggers.add(null);
      release.complete();
      clock.elapse(const Duration(minutes: 10));
      expect(paused, isTrue);
      expect(runs, 1);

      scheduler.dispose();
      triggers.close();
    });
  });

  test('pause during a run hung on an RPC ends once the RPC times out, and '
      'the run backs off as a network failure (DEV-186, AUTH-004)', () {
    fakeAsync((clock) {
      final api = SupabaseSyncApi(
        ensureSession: () async {},
        rpc: (_, _) => Completer<Object?>().future,
      );
      Object? failure;
      final scheduler = SyncScheduler(
        run: () => api.changes(0, 500),
        triggers: const Stream.empty(),
        onFailed: (error) async => failure = error,
      )..start();
      clock.elapse(Duration.zero);

      var paused = false;
      scheduler.pause().then((_) => paused = true);
      clock.elapse(SupabaseSyncApi.rpcTimeout - const Duration(seconds: 1));
      expect(paused, isFalse);

      clock.elapse(const Duration(seconds: 1));
      expect(paused, isTrue);
      expect(failure, isA<TimeoutException>());
      expect(classifySyncFailure(failure!), SyncFailureKind.network);

      scheduler.dispose();
    });
  });
}
