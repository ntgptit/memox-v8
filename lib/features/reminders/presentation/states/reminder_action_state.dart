import 'package:flutter/foundation.dart';

/// A reminder operation screen 24 starts (UC-REMINDER-001).
enum ReminderOperation { turnOn, turnOff, changeTime }

/// What the last operation left for screen 24 to say. Held in the
/// controller, never stored (reminders spec §9, "For FE-B5").
enum ReminderProblem {
  /// E1: the permission was refused; the reminder stays off.
  permissionDenied,

  /// E3 on Enable: nothing was scheduled; the reminder stays off.
  couldNotTurnOn,

  /// E3 on Change time: the old time and its schedule stand.
  couldNotChangeTime,

  /// E6: the reminder is off, but one already scheduled may still fire.
  mayStillShow,
}

/// E4: a save failed and nothing changed. A new object per failure, so a
/// listener hears two in a row.
final class ReminderSaveFailed {
  ReminderSaveFailed(this.operation);

  final ReminderOperation operation;
}

/// Screen 24's own state: the operation in flight and what the last one
/// left. The reminder itself is the stream's (FE-B5 spec D3).
@immutable
final class ReminderActionState {
  const ReminderActionState({this.running, this.problem, this.saveFailed});

  final ReminderOperation? running;
  final ReminderProblem? problem;
  final ReminderSaveFailed? saveFailed;

  bool get isBusy => running != null;
}
