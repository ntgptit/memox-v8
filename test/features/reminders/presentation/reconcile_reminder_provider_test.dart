import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/presentation/providers/reconcile_reminder_provider.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

void main() {
  test(
    'Reconcile runs the use case on the app\'s settings and platform',
    () async {
      final db = openTestDatabase();
      addTearDown(db.close);
      final platform = FakeReminderPlatform();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          reminderPlatformRepositoryProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(container.dispose);

      final outcome = await container.read(reconcileReminderProvider)();

      // A fresh install has the reminder off: Reconcile clears the platform.
      expect(outcome, isA<Ok<DateTime?, ReminderRejection>>());
      expect(platform.calls, [PlatformCall.capability, PlatformCall.cancel]);
    },
  );
}
