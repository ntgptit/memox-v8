import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/presentation/providers/enable_reminder_provider.dart';
import 'package:memox/features/reminders/presentation/providers/reset_app_options_provider.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/settings_fakes.dart';
import '../../../support/test_database.dart';

// Reset app options as the app runs it (DEV-218): the settings' reset and
// the reminder's reconcile in one turn of the gate.
({
  ProviderContainer container,
  FakeReminderPlatform platform,
  FlakySettingsRepository store,
})
_setUp({FakeReminderPlatform? platform}) {
  final db = openTestDatabase();
  addTearDown(db.close);
  final fake = platform ?? FakeReminderPlatform();
  final store = FlakySettingsRepository(SettingsRepositoryImpl(db));
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      reminderPlatformRepositoryProvider.overrideWithValue(fake),
      settingsRepositoryProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, platform: fake, store: store);
}

void main() {
  test('a reset that arrives while Enable runs waits for it, then leaves the '
      'stored reminder and the pending alarm both off', () async {
    final s = _setUp(
      platform: FakeReminderPlatform()..permissionHold = Completer(),
    );
    await s.store.setTheme(theme: ThemeChoice.dark);

    // Enable is past its first step and waits on the permission.
    final enabling = s.container.read(enableReminderProvider)(20 * 60);
    await pumpEventQueue();
    final resetting = s.container.read(resetAppOptionsProvider)();
    await pumpEventQueue();
    expect(s.store.writes, 1, reason: 'the reset waits behind Enable');

    s.platform.permissionHold!.complete();
    await enabling;
    await resetting;

    final stored = await s.store.watchAppSettings().first;
    expect(stored.reminder.isEnabled, isFalse);
    expect(
      stored.reminder.minuteOfDay,
      AppSettingsEntity.defaults.reminder.minuteOfDay,
    );
    expect(stored.theme, ThemeChoice.system);
    expect(s.platform.pending, isNull);
    expect(s.platform.calls, [
      PlatformCall.capability,
      PlatformCall.requestPermission,
      PlatformCall.schedule,
      PlatformCall.capability,
      PlatformCall.cancel,
    ]);
  });

  test(
    'a reset that fails leaves as its Failure and touches no alarm',
    () async {
      final s = _setUp();
      s.store.isFailing = true;

      await expectLater(
        s.container.read(resetAppOptionsProvider)(),
        throwsA(isA<Failure>()),
      );
      expect(s.platform.calls, isEmpty);
    },
  );
}
