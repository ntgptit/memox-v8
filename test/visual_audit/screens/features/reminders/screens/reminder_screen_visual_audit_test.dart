import 'package:flutter/material.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';

import '../../../../../support/fake_reminder_platform.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 24, Daily reminder off', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: ReminderScreen,
      pump: (brightness, scale) async {
        await tester.pumpWidget(const SizedBox());
        await pumpLibraryScreen(
          tester,
          env,
          const ReminderScreen(),
          brightness: brightness,
          textScale: scale,
          overrides: [
            reminderPlatformRepositoryProvider.overrideWithValue(
              FakeReminderPlatform(),
            ),
          ],
        );
      },
    );
  });
}
