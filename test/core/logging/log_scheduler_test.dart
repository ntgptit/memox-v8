import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/di/logging_providers.dart';

// ADR-018 §3: logs are shipped while the app is in front.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('the log scheduler', () {
    /// Runs [body] on a fake clock with a started scheduler, past its run at
    /// start; `settle` elapses the debounce.
    void withScheduler(
      void Function(
        StreamController<void> periodic,
        StreamController<void> reconnects,
        void Function(bool) setForeground,
        int Function() runs,
        void Function() settle,
      )
      body,
    ) {
      fakeAsync((async) {
        final periodic = StreamController<void>.broadcast();
        final reconnects = StreamController<void>.broadcast();
        var runs = 0;
        var foreground = true;
        final scheduler = startLogScheduler(
          run: () async => runs++,
          periodic: periodic.stream,
          reconnects: reconnects.stream,
          isForeground: () => foreground,
          debounce: const Duration(milliseconds: 10),
        );
        void settle() => async.elapse(const Duration(milliseconds: 60));
        settle();
        expect(runs, 1);

        body(
          periodic,
          reconnects,
          (value) => foreground = value,
          () => runs,
          settle,
        );

        scheduler.dispose();
        periodic.close();
        reconnects.close();
        async.flushMicrotasks();
      });
    }

    test('the periodic push runs while the app is in front', () {
      withScheduler((periodic, _, _, runs, settle) {
        periodic.add(null);
        settle();

        expect(runs(), 2);
      });
    });

    test('the periodic push is dropped while the app is not in front', () {
      withScheduler((periodic, _, setForeground, runs, settle) {
        setForeground(false);

        periodic.add(null);
        settle();

        expect(runs(), 1);
      });
    });

    test('a reconnect runs while the app is in front', () {
      withScheduler((_, reconnects, _, runs, settle) {
        reconnects.add(null);
        settle();

        expect(runs(), 2);
      });
    });

    test('a reconnect is dropped while the app is not in front', () {
      withScheduler((_, reconnects, setForeground, runs, settle) {
        setForeground(false);

        reconnects.add(null);
        settle();

        expect(runs(), 1);
      });
    });

    test('a dropped push is not queued for the return to the front (the '
        'resume calls syncNow)', () {
      withScheduler((periodic, _, setForeground, runs, settle) {
        setForeground(false);
        periodic.add(null);
        settle();
        setForeground(true);
        settle();

        expect(runs(), 1);
      });
    });
  });

  group('isForegroundProvider', () {
    test('is true only while the app lifecycle state is resumed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final isForeground = container.read(isForegroundProvider);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(isForeground(), isFalse);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(isForeground(), isFalse);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(isForeground(), isTrue);
    });
  });
}
