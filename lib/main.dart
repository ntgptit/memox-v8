import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/logging_bootstrap.dart';
import 'package:memox/app/startup_settings.dart';
import 'package:memox/app/startup_welcome.dart';
import 'package:memox/app/sync_tables.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/logging/log_provider_observer.dart';
import 'package:memox/core/network/supabase_client.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/reminders/di/reminder_plugins_data_source_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DB errors are mapped to Failure explicitly (core/error/failure.dart);
  // Riverpod's default retry-on-error would otherwise sit a failed provider
  // in a hidden retry loop while showing AsyncLoading. Every provider that
  // fails is logged (ADR-018).
  final container = ProviderContainer(
    // Core's sync and account reset see the app's tables (DEV-173).
    overrides: syncTableOverrides,
    retry: _noRetry,
    observers: [LogProviderObserver()],
  );
  await installAppLogger(container);
  // The stored theme and language before the first frame (FE-A3 D5).
  final settings = await readStartupSettings(container);
  // ADR-015: sync starts with the app when this build names a Supabase project.
  final supabase = container.read(supabaseConfigProvider);
  if (supabase.isEnabled) {
    // Every request, auth and RPC, is logged (ADR-018; spec
    // 2026-09-29-network-logging-design.md).
    await initializeSupabase(supabase);
  }
  // Auth spec R3: a pending account transition shuts the write gate before
  // the first frame. The rest of the start runs in the background: the
  // first frame never waits for the network (R1, R2).
  final accounts = container.read(accountCoordinatorProvider);
  await accounts?.prepare();
  // Account UI spec U1: the first launch's Welcome, before the first frame.
  await showWelcomeIfDue(container);
  container
    ..read(syncSchedulerProvider)
    ..read(logSchedulerProvider);
  if (accounts != null) unawaited(accounts.start());
  // BE-B5b: the reminder's plugins, on Android only, before anything
  // schedules. A failure here leaves the reminder to report its own typed
  // reason when it is used; the app starts regardless.
  try {
    await container.read(reminderPluginsDataSourceProvider)?.initialize();
  } on Object catch (error, stackTrace) {
    appLogger.warning(
      'reminder.plugins_failed',
      category: LogCategory.reminder,
      error: error,
      stackTrace: stackTrace,
    );
  }
  appLogger.info('lifecycle.start', category: LogCategory.lifecycle);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MemoxApp(initialSettings: settings),
    ),
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
