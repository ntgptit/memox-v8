import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/features/reminders/di/reminder_background_bindings.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/presentation/providers/deliver_reminder_use_case_provider.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

/// The fire's log buffer, in memory (the real one needs path_provider).
Override _memoryLogs() =>
    logDatabaseProvider.overrideWithValue(LogDatabase(NativeDatabase.memory()));

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
}
