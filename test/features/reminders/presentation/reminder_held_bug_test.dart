import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/presentation/controllers/reminder_controller.dart';
import 'package:memox/features/reminders/presentation/providers/change_reminder_time_provider.dart';
import 'package:memox/features/reminders/presentation/providers/disable_reminder_provider.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';

import '../../../support/held_bug.dart';
import '../../../support/held_bug_capture.dart';

// LIB-6: a held write that meets a bug releases its flow and reports the
// bug (runHeld). Screen 24 shows the failed save (E4) with Try again, as for
// a Failure.
void main() {
  ProviderContainer buggy() {
    final container = ProviderContainer(
      overrides: [
        disableReminderProvider.overrideWithValue(() async => throw heldBug()),
        changeReminderTimeProvider.overrideWithValue(
          (_) async => throw heldBug(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(reminderControllerProvider, (_, _) {});
    return container;
  }

  test('a turn off that dies on a bug is no longer busy and fails the save '
      '(E4)', () async {
    final container = buggy();
    final reported = captureReportedBugs();

    await container.read(reminderControllerProvider.notifier).turnOff();

    expectOneBugReported(reported);
    final state = container.read(reminderControllerProvider);
    expect(state.isBusy, isFalse);
    expect(state.problem, isNull);
    expect(state.saveFailed!.operation, ReminderOperation.turnOff);
  });

  test('a change of time that dies on a bug fails the save, and Try again '
      'repeats it', () async {
    final container = buggy();
    final reported = captureReportedBugs();
    final controller = container.read(reminderControllerProvider.notifier);

    await controller.changeTime(480);
    await controller.retry();

    expect(reported, hasLength(2));
    final state = container.read(reminderControllerProvider);
    expect(state.isBusy, isFalse);
    expect(state.saveFailed!.operation, ReminderOperation.changeTime);
  });
}
