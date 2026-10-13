import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/buffer_sink.dart';
import 'package:memox/core/logging/console_sink.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/network/di/network_providers.dart';
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
/// and the next Reconcile schedules again. The isolate logs to the device's
/// log buffer as the app does, and writes it before the container closes, so
/// a failed fire reaches monitoring.
Future<void> runReminderDelivery(
  ProviderContainer container, {
  bool console = kDebugMode,
}) async {
  final previous = appLogger;
  final buffer = _installBufferedLogger(container, console: console);
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
    await appLogger.flush();
    buffer?.dispose();
    AppLogger.install(previous);
    container.dispose();
  }
}

/// The log buffer, and the console in a debug build ([console]); the console
/// alone when the buffer cannot open. A build with no Supabase project has no
/// buffer: its logs could never be shipped.
BufferSink? _installBufferedLogger(
  ProviderContainer container, {
  required bool console,
}) {
  try {
    final buffer = container.read(supabaseConfigProvider).isEnabled
        ? BufferSink(container.read(logDatabaseProvider))
        : null;
    AppLogger.install(
      AppLogger(sinks: [if (console) const ConsoleSink(), ?buffer]),
    );
    return buffer;
  } on Object {
    return null;
  }
}
