import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_permission_provider.g.dart';

/// The notification permission as it stands now (BR-REMINDER-011 amended,
/// SP2b 2.34): read when screen 24 opens, again when the app resumes (the
/// screen invalidates it), and never asked for.
@riverpod
Future<ReminderPermission> reminderPermission(Ref ref) {
  // Read again whenever the reminder is turned on or off: a read from before
  // the person allowed notifications would warn about a reminder that was
  // just turned on.
  ref.watch(
    reminderStatusProvider.select((status) => status.value?.reminder.isEnabled),
  );
  return ref.watch(reminderPlatformRepositoryProvider).notificationPermission();
}
