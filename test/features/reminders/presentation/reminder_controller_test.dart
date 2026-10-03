import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/presentation/controllers/reminder_controller.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

// Screen 24's operations (UC-REMINDER-001; FE-B5 spec D3, D4).

({
  ProviderContainer container,
  FakeReminderPlatform platform,
  FlakySettingsRepository store,
})
_setUp(LibraryEnv env, {FakeReminderPlatform? platform}) {
  final fake = platform ?? FakeReminderPlatform();
  final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
  final container = libraryContainer(
    env,
    overrides: [
      reminderPlatformRepositoryProvider.overrideWithValue(fake),
      settingsRepositoryProvider.overrideWithValue(store),
    ],
  );
  // The screen keeps the stream alive; so does the test.
  container.listen(reminderStatusProvider, (_, _) {});
  return (container: container, platform: fake, store: store);
}

ReminderController _controller(ProviderContainer c) =>
    c.read(reminderControllerProvider.notifier);

void main() {
  libraryTest('turnOn: Enable at the stored minute, then idle', (
    tester,
    env,
  ) async {
    final s = _setUp(env);
    await s.container.read(reminderStatusProvider.future);

    await _controller(s.container).turnOn();

    expect(s.platform.calls, contains(PlatformCall.requestPermission));
    expect(s.platform.pending, isNotNull);
    expect(s.container.read(reminderControllerProvider).problem, isNull);
    expect(s.container.read(reminderControllerProvider).isBusy, isFalse);
  });

  libraryTest('turnOn refused: permissionDenied, then Retry asks again', (
    tester,
    env,
  ) async {
    final s = _setUp(
      env,
      platform: FakeReminderPlatform(permission: ReminderPermission.denied),
    );
    await s.container.read(reminderStatusProvider.future);

    await _controller(s.container).turnOn();
    expect(
      s.container.read(reminderControllerProvider).problem,
      ReminderProblem.permissionDenied,
    );

    s.platform.permission = ReminderPermission.granted;
    await _controller(s.container).retry();
    expect(s.container.read(reminderControllerProvider).problem, isNull);
    expect(
      s.platform.calls.where((c) => c == PlatformCall.requestPermission),
      hasLength(2),
    );
  });

  libraryTest(
    'couldNotSchedule is couldNotTurnOn on Enable and couldNotChangeTime on a change',
    (tester, env) async {
      final s = _setUp(env);
      await s.container.read(reminderStatusProvider.future);
      await _controller(s.container).turnOn();
      s.platform.refusing.add(PlatformCall.schedule);

      await _controller(s.container).changeTime(21 * 60);
      expect(
        s.container.read(reminderControllerProvider).problem,
        ReminderProblem.couldNotChangeTime,
      );

      await _controller(s.container).turnOff();
      await _controller(s.container).turnOn();
      expect(
        s.container.read(reminderControllerProvider).problem,
        ReminderProblem.couldNotTurnOn,
      );
    },
  );

  libraryTest(
    'turnOff with a refused cancel: mayStillShow; Retry only cancels',
    (tester, env) async {
      final s = _setUp(env);
      await s.container.read(reminderStatusProvider.future);
      await _controller(s.container).turnOn();
      s.platform.refusing.add(PlatformCall.cancel);

      await _controller(s.container).turnOff();
      expect(
        s.container.read(reminderControllerProvider).problem,
        ReminderProblem.mayStillShow,
      );

      s.platform.refusing.clear();
      final writes = s.store.writes;
      await _controller(s.container).retry();
      expect(s.container.read(reminderControllerProvider).problem, isNull);
      expect(s.store.writes, writes, reason: 'E6: Try again writes nothing');
    },
  );

  libraryTest('a failed save is ReminderSaveFailed, never a problem (E4)', (
    tester,
    env,
  ) async {
    final s = _setUp(env);
    await s.container.read(reminderStatusProvider.future);
    s.store.isFailing = true;

    await _controller(s.container).turnOn();

    final state = s.container.read(reminderControllerProvider);
    expect(state.problem, isNull);
    expect(state.saveFailed?.operation, ReminderOperation.turnOn);
    expect(
      s.platform.pending,
      isNull,
      reason: 'Enable takes the schedule back',
    );
  });

  libraryTest('a second operation is ignored while one runs', (
    tester,
    env,
  ) async {
    final s = _setUp(env);
    await s.container.read(reminderStatusProvider.future);
    final hold = Completer<void>();
    s.store.hold = hold;

    final first = _controller(s.container).turnOn();
    await tester.pump();
    expect(
      s.container.read(reminderControllerProvider).running,
      ReminderOperation.turnOn,
    );
    await _controller(s.container).turnOff();
    hold.complete();
    await first;

    expect(
      s.platform.calls.where((c) => c == PlatformCall.requestPermission),
      hasLength(1),
    );
    expect(s.platform.calls, isNot(contains(PlatformCall.cancel)));
  });

  libraryTest('the outcome survives a stream re-emission', (tester, env) async {
    final s = _setUp(
      env,
      platform: FakeReminderPlatform(permission: ReminderPermission.denied),
    );
    await s.container.read(reminderStatusProvider.future);
    await _controller(s.container).turnOn();

    // Another write to app_settings re-emits the stream.
    await s.store.saveReminder(
      reminder: const ReminderSettings(isEnabled: false, minuteOfDay: 1260),
    );
    await s.container.read(reminderStatusProvider.future);

    expect(
      s.container.read(reminderControllerProvider).problem,
      ReminderProblem.permissionDenied,
    );
  });

  libraryTest('clearPermissionProblem: the refused-permission problem goes, '
      'and Retry has nothing left to repeat (SP2b 2.36)', (tester, env) async {
    final s = _setUp(
      env,
      platform: FakeReminderPlatform(permission: ReminderPermission.denied),
    );
    await s.container.read(reminderStatusProvider.future);
    await _controller(s.container).turnOn();
    expect(
      s.container.read(reminderControllerProvider).problem,
      ReminderProblem.permissionDenied,
    );
    final writes = s.store.writes;

    _controller(s.container).clearPermissionProblem();
    expect(s.container.read(reminderControllerProvider).problem, isNull);
    await _controller(s.container).retry();

    expect(
      s.platform.calls.where((c) => c == PlatformCall.requestPermission),
      hasLength(1),
      reason: 'BR-REMINDER-011: nothing asks again by itself',
    );
    expect(s.store.writes, writes);
  });

  libraryTest('clearPermissionProblem leaves every other problem alone', (
    tester,
    env,
  ) async {
    final s = _setUp(
      env,
      platform: FakeReminderPlatform()..refusing.add(PlatformCall.schedule),
    );
    await s.container.read(reminderStatusProvider.future);
    await _controller(s.container).turnOn();

    _controller(s.container).clearPermissionProblem();

    expect(
      s.container.read(reminderControllerProvider).problem,
      ReminderProblem.couldNotTurnOn,
    );
  });
}
