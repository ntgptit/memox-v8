import 'dart:developer';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// connection, even when Deliver throws. A fire that fails is logged by type
/// only (BR-REMINDER-005: nothing of the digest leaves the notification) and
/// the next Reconcile schedules again.
Future<void> runReminderDelivery(ProviderContainer container) async {
  try {
    await container.read(deliverReminderUseCaseProvider)();
  } on Object catch (error) {
    log('The reminder fire failed: ${error.runtimeType}', name: 'reminders');
  } finally {
    container.dispose();
  }
}
