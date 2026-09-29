import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/buffer_sink.dart';
import 'package:memox/core/logging/console_sink.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/logging/log_entry.dart' show LogSink;
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/reminders/di/reminder_background_bindings.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/presentation/providers/deliver_reminder_use_case_provider.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

/// The fire's log buffer, in memory (the real one needs path_provider).
Override _memoryLogs() =>
    logDatabaseProvider.overrideWithValue(LogDatabase(NativeDatabase.memory()));

const _enabled = SupabaseConfig(
  url: 'https://x.supabase.co',
  publishableKey: 'k',
);
const _disabled = SupabaseConfig(url: '', publishableKey: '');

/// The sinks the isolate's logger has while Deliver runs.
Future<List<LogSink>> _sinksDuringFire({
  required SupabaseConfig config,
  required bool console,
}) async {
  final logs = LogDatabase(NativeDatabase.memory());
  late List<LogSink> sinks;
  final container = ProviderContainer(
    overrides: [
      supabaseConfigProvider.overrideWithValue(config),
      logDatabaseProvider.overrideWithValue(logs),
      deliverReminderUseCaseProvider.overrideWith((ref) {
        sinks = appLogger.sinks;
        throw StateError('stop here');
      }),
    ],
  );

  await runReminderDelivery(container, console: console);
  await logs.close();

  return sinks;
}

void main() {
  // The production databaseProvider closes its connection in onDispose; these
  // tests prove the fire disposes what it opened, by an onDispose of their own.

  test('the fire runs Deliver once, then disposes what it opened', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    var disposed = false;
    final platform = FakeReminderPlatform(
      capabilityValue: ReminderCapability.unsupported,
    );
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) {
          ref.onDispose(() => disposed = true);
          return db;
        }),
        reminderPlatformRepositoryProvider.overrideWithValue(platform),
        _memoryLogs(),
      ],
    );
    // Deliver on an unsupported platform stops before the database; read it
    // here so the fire's container holds it, as a supported fire would.
    container.read(databaseProvider);

    await runReminderDelivery(container);

    expect(platform.calls, [PlatformCall.capability]);
    expect(disposed, isTrue);
  });

  test('a Deliver that throws still disposes what it opened', () async {
    var disposed = false;
    final container = ProviderContainer(
      overrides: [
        deliverReminderUseCaseProvider.overrideWith((ref) {
          ref.onDispose(() => disposed = true);
          throw StateError('no database');
        }),
        _memoryLogs(),
      ],
    );

    await runReminderDelivery(container);

    expect(disposed, isTrue);
  });

  test('a Deliver that throws is written to the log buffer before the fire '
      'ends (ADR-018: background failures reach monitoring)', () async {
    final logs = LogDatabase(NativeDatabase.memory());
    addTearDown(logs.close);
    final container = ProviderContainer(
      overrides: [
        supabaseConfigProvider.overrideWithValue(_enabled),
        logDatabaseProvider.overrideWithValue(logs),
        deliverReminderUseCaseProvider.overrideWith(
          (ref) => throw StateError('no database'),
        ),
      ],
    );

    await runReminderDelivery(container);

    final rows = await logs.oldest(10);
    expect(rows.map((e) => e.event), ['reminder.fire_failed']);
  });

  group('the isolate logger', () {
    test('has the console and the buffer when console is true', () async {
      final sinks = await _sinksDuringFire(config: _enabled, console: true);

      expect(sinks.whereType<ConsoleSink>(), hasLength(1));
      expect(sinks.whereType<BufferSink>(), hasLength(1));
    });

    test('leaves the console out when console is false', () async {
      final sinks = await _sinksDuringFire(config: _enabled, console: false);

      expect(sinks.whereType<ConsoleSink>(), isEmpty);
      expect(sinks.whereType<BufferSink>(), hasLength(1));
    });

    test('has no buffer in a build without a Supabase project', () async {
      final sinks = await _sinksDuringFire(config: _disabled, console: true);

      expect(sinks.whereType<ConsoleSink>(), hasLength(1));
      expect(sinks.whereType<BufferSink>(), isEmpty);
    });
  });
}
