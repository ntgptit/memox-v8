import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import 'fake_reminder_platform.dart';
import 'library_harness.dart';
import 'settings_fakes.dart';

// Screen 24, Daily reminder: the pump the screen's test files share.

/// Lets the screen's reads and the platform's answers land.
Future<void> settleReminderScreen(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Screen 24 over [env], with a fake platform and a settings store that can
/// fail on demand.
Future<({FakeReminderPlatform platform, FlakySettingsRepository store})>
pumpReminderScreen(
  WidgetTester tester,
  LibraryEnv env, {
  FakeReminderPlatform? platform,
  List<Override> overrides = const [],
}) async {
  final fake = platform ?? FakeReminderPlatform();
  final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
  await pumpLibraryScreen(
    tester,
    env,
    const ReminderScreen(),
    overrides: [
      reminderPlatformRepositoryProvider.overrideWithValue(fake),
      settingsRepositoryProvider.overrideWithValue(store),
      ...overrides,
    ],
  );
  await settleReminderScreen(tester);
  return (platform: fake, store: store);
}

/// Taps the reminder toggle and settles.
Future<void> tapReminderToggle(WidgetTester tester) async {
  await tester.tap(find.byType(MxToggle));
  await settleReminderScreen(tester);
}
