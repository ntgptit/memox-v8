import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/library_harness.dart';
import '../../../support/reminder_screen_harness.dart';
import '../../../support/settings_fakes.dart';

// Screen 24, permDenied: the banner body wraps to 3 lines at 360 dp (DEV-359);
// the screen holds at the smallest viewport and the largest text scale.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('permDenied: 320 x 640 at text scale 1.3 overflows nothing', (
    tester,
    env,
  ) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
    await pumpLibraryScreen(
      tester,
      env,
      const ReminderScreen(),
      textScale: 1.3,
      overrides: [
        reminderPlatformRepositoryProvider.overrideWithValue(
          FakeReminderPlatform(permission: ReminderPermission.denied),
        ),
        settingsRepositoryProvider.overrideWithValue(store),
      ],
    );
    tester.view.physicalSize = const Size(320, 640);
    await settleReminderScreen(tester);
    await tapReminderToggle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(find.text(_en.reminderDeniedBody), findsOneWidget);
    final banner = tester.getRect(find.byType(MxInlineBanner));
    expect(banner.left, greaterThanOrEqualTo(0));
    expect(banner.right, lessThanOrEqualTo(320));
    printOnFailure(
      'MEASURED reminder screen permDenied 320x640 x1.3: banner '
      '${banner.width.toStringAsFixed(1)} x ${banner.height.toStringAsFixed(1)}',
    );
  });
}
