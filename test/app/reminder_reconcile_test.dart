import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';

import '../support/fake_reminder_platform.dart';
import '../support/library_harness.dart';

void main() {
  libraryTest('the app reconciles the reminder at start and on every resume '
      '(BR-REMINDER-009: an offset change while the app sleeps)', (
    tester,
    env,
  ) async {
    final platform = FakeReminderPlatform();
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        reminderPlatformRepositoryProvider.overrideWithValue(platform),
      ],
    );
    final atStart = platform.calls
        .where((c) => c == PlatformCall.cancel)
        .length;
    expect(atStart, 1);

    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(platform.calls.where((c) => c == PlatformCall.cancel), hasLength(2));
  });
}
