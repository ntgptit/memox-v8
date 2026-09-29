import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/features/reminders/presentation/providers/deliver_reminder_use_case_provider.dart';

/// What the alarm runs, in its own background isolate (UC-REMINDER-001 step
/// 4, BE-B5b). The isolate shares nothing with the app: it opens its own
/// providers and database connection, and closes them when the fire is done.
@pragma('vm:entry-point')
Future<void> deliverReminderInBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await runReminderDelivery(ProviderContainer());
}

/// Runs Deliver in [container], then disposes it, which closes the database
/// connection, even when Deliver throws. A fire that fails is logged (ADR-018)
/// and the next Reconcile schedules again. The isolate has no log buffer of
/// its own, so the entry reaches the console only.
Future<void> runReminderDelivery(ProviderContainer container) async {
  try {
    await container.read(deliverReminderUseCaseProvider)();
  } on Object catch (error, stackTrace) {
    appLogger.warning(
      'reminder.fire_failed',
      category: LogCategory.reminder,
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    container.dispose();
  }
}
