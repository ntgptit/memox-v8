import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/logging_bootstrap.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/buffer_sink.dart';
import 'package:memox/core/logging/console_sink.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/network/di/network_providers.dart';

import '../support/test_database.dart';

const _enabled = SupabaseConfig(
  url: 'https://x.supabase.co',
  publishableKey: 'k',
);
const _disabled = SupabaseConfig(url: '', publishableKey: '');

// ADR-018 §3: logging never stops the app from starting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLogger previous;
  late FlutterExceptionHandler? flutterOnError;
  late ErrorCallback? dispatcherOnError;

  setUp(() {
    previous = appLogger;
    flutterOnError = FlutterError.onError;
    dispatcherOnError = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    AppLogger.install(previous);
    FlutterError.onError = flutterOnError;
    PlatformDispatcher.instance.onError = dispatcherOnError;
  });

  /// A container with the log buffer and the sync store in memory.
  ProviderContainer container(SupabaseConfig config) {
    final logs = LogDatabase(NativeDatabase.memory());
    final db = openTestDatabase();
    final container = ProviderContainer(
      overrides: [
        supabaseConfigProvider.overrideWithValue(config),
        logDatabaseProvider.overrideWithValue(logs),
        databaseProvider.overrideWithValue(db),
      ],
      retry: (_, _) => null,
    );
    addTearDown(() async {
      // The prune the install starts runs to its end first.
      await pumpEventQueue();
      container.dispose();
      await logs.close();
      await db.close();
    });
    return container;
  }

  test('a log buffer that cannot open leaves the console logger, and the '
      'start goes on', () async {
    final container = ProviderContainer(
      overrides: [
        supabaseConfigProvider.overrideWithValue(_enabled),
        logDatabaseProvider.overrideWith((ref) => throw StateError('no disk')),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);

    await expectLater(installAppLogger(container), completes);

    expect(identical(appLogger, previous), isTrue);
    expect(FlutterError.onError, isNot(flutterOnError));
  });

  group('the console sink', () {
    // The console choice with a Supabase project (a buffer to ship) and
    // without one (nothing to ship, so no buffer).
    for (final (name, config, console, consoleSinks, bufferSinks) in const [
      ('is installed when console is true', _enabled, true, 1, 1),
      ('is left out when console is false', _enabled, false, 0, 1),
      (
        'keeps only the console choice without a Supabase project',
        _disabled,
        false,
        0,
        0,
      ),
    ]) {
      test(name, () async {
        await installAppLogger(container(config), console: console);

        expect(
          appLogger.sinks.whereType<ConsoleSink>(),
          hasLength(consoleSinks),
        );
        expect(appLogger.sinks.whereType<BufferSink>(), hasLength(bufferSinks));
        expect(appLogger.sinks, hasLength(consoleSinks + bufferSinks));
      });
    }

    test('follows the build mode by default', () async {
      await installAppLogger(container(_enabled));

      expect(appLogger.sinks.whereType<ConsoleSink>().isNotEmpty, kDebugMode);
    });
  });

  group('a build without a Supabase project', () {
    test('does not even open the log database', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseConfigProvider.overrideWithValue(_disabled),
          logDatabaseProvider.overrideWith(
            (ref) => throw StateError('must not open'),
          ),
        ],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);

      await installAppLogger(container, console: true);

      expect(identical(appLogger, previous), isFalse);
      expect(appLogger.sinks.whereType<ConsoleSink>(), hasLength(1));
      expect(appLogger.sinks.whereType<BufferSink>(), isEmpty);
    });
  });
}
