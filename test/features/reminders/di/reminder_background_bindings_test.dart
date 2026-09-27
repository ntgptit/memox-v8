import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/reminders/di/reminder_background_bindings.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/presentation/providers/deliver_reminder_use_case_provider.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

void main() {
  test('the fire runs Deliver once, then lets its container go', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final platform = FakeReminderPlatform(
      capabilityValue: ReminderCapability.unsupported,
    );
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        reminderPlatformRepositoryProvider.overrideWithValue(platform),
      ],
    );

    await runReminderDelivery(container);

    expect(platform.calls, [PlatformCall.capability]);
    expect(() => container.read(databaseProvider), throwsStateError);
  });

  test('a Deliver that throws still lets its container go', () async {
    final container = ProviderContainer(
      overrides: [
        deliverReminderUseCaseProvider.overrideWith(
          (ref) => throw StateError('no database'),
        ),
      ],
    );

    await runReminderDelivery(container);

    expect(
      () => container.read(deliverReminderUseCaseProvider),
      throwsStateError,
    );
  });
}
