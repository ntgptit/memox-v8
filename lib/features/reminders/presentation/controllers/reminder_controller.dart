import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/presentation/providers/change_reminder_time_provider.dart';
import 'package:memox/features/reminders/presentation/providers/disable_reminder_provider.dart';
import 'package:memox/features/reminders/presentation/providers/enable_reminder_provider.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_controller.g.dart';

/// Screen 24's operations (UC-REMINDER-001): one at a time (spec D4), each
/// leaving at most one problem or one failed save, and Retry repeats the
/// operation that left it. Widgets draw this state and the stream.
@riverpod
class ReminderController extends _$ReminderController {
  /// What Retry repeats; null once an operation ended well.
  Future<void> Function()? _again;

  @override
  ReminderActionState build() => const ReminderActionState();

  int get _storedMinute =>
      ref.read(reminderStatusProvider).value?.reminder.minuteOfDay ??
      ReminderSettings.defaultMinuteOfDay;

  /// The toggle on, or Try again after a refusal: only here is the
  /// permission asked (BR-REMINDER-011).
  Future<void> turnOn() => _run(
    ReminderOperation.turnOn,
    () => ref.read(enableReminderProvider)(_storedMinute),
    again: turnOn,
  );

  /// The toggle off, or Try again after `mayStillShow` (A2, E6).
  Future<void> turnOff() => _run(
    ReminderOperation.turnOff,
    () => ref.read(disableReminderProvider)(),
    again: turnOff,
  );

  /// Save in the time dialog (A1).
  Future<void> changeTime(int minuteOfDay) => _run(
    ReminderOperation.changeTime,
    () => ref.read(changeReminderTimeProvider)(minuteOfDay),
    again: () => changeTime(minuteOfDay),
  );

  /// Repeats the operation that left the current problem or failed save.
  Future<void> retry() async {
    final again = _again;
    if (again != null) await again();
  }

  Future<void> _run(
    ReminderOperation operation,
    Future<Outcome<Object?, ReminderRejection>> Function() call, {
    required Future<void> Function() again,
  }) async {
    if (state.isBusy) return;
    state = ReminderActionState(running: operation);
    ReminderProblem? problem;
    ReminderSaveFailed? saveFailed;
    try {
      if (await call() case Rejected(:final reason)) {
        problem = _problemOf(operation, reason);
      }
    } on Failure {
      saveFailed = ReminderSaveFailed(operation);
    }
    if (!ref.mounted) return;
    _again = problem != null || saveFailed != null ? again : null;
    state = ReminderActionState(problem: problem, saveFailed: saveFailed);
  }

  static ReminderProblem? _problemOf(
    ReminderOperation operation,
    ReminderRejection reason,
  ) => switch (reason) {
    ReminderRejection.permissionDenied => ReminderProblem.permissionDenied,
    ReminderRejection.couldNotSchedule =>
      operation == ReminderOperation.changeTime
          ? ReminderProblem.couldNotChangeTime
          : ReminderProblem.couldNotTurnOn,
    ReminderRejection.couldNotCancel => ReminderProblem.mayStillShow,
    // The stream already says the platform has none (BR-REMINDER-012); the
    // dialog's bounds keep the minute in range; only a delivery shows.
    ReminderRejection.unsupported ||
    ReminderRejection.minuteOutOfRange ||
    ReminderRejection.couldNotShow => null,
  };
}
