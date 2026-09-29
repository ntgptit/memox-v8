import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/di/logging_providers.dart';

// ADR-018 §3: logs are shipped while the app is in front.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('the log scheduler', () {
    late StreamController<void> periodic;
    late StreamController<void> reconnects;
    late int runs;
    late bool foreground;

    setUp(() {
      periodic = StreamController<void>.broadcast();
      reconnects = StreamController<void>.broadcast();
      runs = 0;
      foreground = true;
    });

    tearDown(() async {
      await periodic.close();
      await reconnects.close();
    });

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 60));

    /// Started, and past its run at start.
    Future<void> start() async {
      final scheduler = startLogScheduler(
        run: () async => runs++,
        periodic: periodic.stream,
        reconnects: reconnects.stream,
        isForeground: () => foreground,
        debounce: const Duration(milliseconds: 10),
      );
      addTearDown(scheduler.dispose);
      await settle();
      expect(runs, 1);
    }

    test('the periodic push runs while the app is in front', () async {
      await start();

      periodic.add(null);
      await settle();

      expect(runs, 2);
    });

    test(
      'the periodic push is dropped while the app is not in front',
      () async {
        await start();
        foreground = false;

        periodic.add(null);
        await settle();

        expect(runs, 1);
      },
    );

    test('a reconnect runs while the app is in front', () async {
      await start();

      reconnects.add(null);
      await settle();

      expect(runs, 2);
    });

    test('a reconnect is dropped while the app is not in front', () async {
      await start();
      foreground = false;

      reconnects.add(null);
      await settle();

      expect(runs, 1);
    });

    test('a dropped push is not queued for the return to the front (the '
        'resume calls syncNow)', () async {
      await start();
      foreground = false;
      periodic.add(null);
      await settle();
      foreground = true;
      await settle();

      expect(runs, 1);
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
