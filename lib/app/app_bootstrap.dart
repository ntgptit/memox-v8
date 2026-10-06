import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/logging_bootstrap.dart';
import 'package:memox/app/startup_settings.dart';
import 'package:memox/app/startup_welcome.dart';
import 'package:memox/app/sync_tables.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/logging/log_provider_observer.dart';
import 'package:memox/core/network/supabase_client.dart' as supabase;
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/reminders/di/reminder_plugins_data_source_provider.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';

/// How the start ended: what the first frame needs, or why there is none.
sealed class StartupResult {
  const StartupResult();
}

/// The app can start: [settings] is the row `startApp` read before the first
/// frame (FE-A3 D5), null when the read failed or was slow.
final class StartupReady extends StartupResult {
  const StartupReady(this.settings);

  final AppSettingsEntity? settings;
}

/// The database did not open (DEV-195): a migration that stopped, a file
/// that cannot be read, a full disk. [migration] names the step that stopped
/// when it was one. The app shows the recovery screen instead.
final class StartupDatabaseUnavailable extends StartupResult {
  const StartupDatabaseUnavailable(
    this.error,
    this.stackTrace, {
    this.migration,
  });

  final Object error;
  final StackTrace stackTrace;

  /// The `(from, to)` of the upgrade step that stopped, if the open failed
  /// inside one.
  final (int, int)? migration;
}

/// The app's container: core's sync and account reset see the app's tables
/// (DEV-173); a provider that fails is logged (ADR-018) and never retried in
/// a hidden loop, since DB errors are mapped to [Failure] explicitly
/// (core/error/failure.dart) and shown as what they are.
ProviderContainer buildAppContainer() => ProviderContainer(
  overrides: syncTableOverrides,
  retry: _noRetry,
  observers: [LogProviderObserver()],
);

Duration? _noRetry(int retryCount, Object error) => null;

/// The start, in the order the specs fix (DEV-176), before the first frame:
///
/// 1. the logger, so what starts after it logs to the buffer (ADR-018 §3);
/// 2. the Supabase project, before anything reads the account coordinator
///    (ADR-015; every request is logged, spec 2026-09-29-network-logging);
/// 3. the rest, from the database on ([retryStartApp] runs it again).
///
/// [initializeSupabase] is the SDK's; a test passes its own.
Future<StartupResult> startApp(
  ProviderContainer container, {
  Future<void> Function(SupabaseConfig) initializeSupabase =
      supabase.initializeSupabase,
}) async {
  await installAppLogger(container);
  final config = container.read(supabaseConfigProvider);
  if (config.isEnabled) await initializeSupabase(config);
  return _startFromDatabase(container);
}

/// Retry on the recovery screen (DEV-195): a fresh connection, then the
/// start from the database on. The logger and the SDK are installed once.
Future<StartupResult> retryStartApp(ProviderContainer container) {
  container.invalidate(databaseProvider);
  return _startFromDatabase(container);
}

Future<StartupResult> _startFromDatabase(ProviderContainer container) async {
  final unavailable = await _openDatabase(container);
  if (unavailable != null) return unavailable;
  final settings = await readStartupSettings(container);
  final accounts = await _prepareAccounts(container);
  await showWelcomeIfDue(container);
  _startSchedulers(container);
  if (accounts != null) unawaited(accounts.start());
  await _initializeReminderPlugins(container);
  appLogger.info('lifecycle.start', category: LogCategory.lifecycle);
  return StartupReady(settings);
}

/// DEV-195: the database opens on purpose, before anything reads it. A file
/// that cannot open is a result the recovery screen shows, logged to the
/// buffer (its own file, which usually still opens), instead of an error
/// under a frame that never paints. Nothing is deleted or repaired here.
Future<StartupDatabaseUnavailable?> _openDatabase(
  ProviderContainer container,
) async {
  final db = container.read(databaseProvider);
  try {
    await db.ensureOpened();
    return null;
  } on Object catch (error, stackTrace) {
    final migration = db.lastMigrationFailure;
    appLogger.error(
      'lifecycle.database_unavailable',
      category: LogCategory.lifecycle,
      error: error,
      stackTrace: stackTrace,
      context: {
        if (migration != null) 'migration': '${migration.$1}->${migration.$2}',
      },
    );
    return StartupDatabaseUnavailable(error, stackTrace, migration: migration);
  }
}

/// Auth spec R3: a pending account transition shuts the write gate before
/// the first frame, and before Welcome asks anything (account UI spec U1).
/// Local only: the first frame never waits for the network (R1, R2).
Future<AccountCoordinator?> _prepareAccounts(
  ProviderContainer container,
) async {
  final accounts = container.read(accountCoordinatorProvider);
  await accounts?.prepare();
  return accounts;
}

/// Both schedulers are read here and nowhere else: each starts in its
/// provider's `build` (paused until the account is Ready, R2) and lives as
/// long as the container. They exist before the coordinator starts, so its
/// first resume has a scheduler to resume.
void _startSchedulers(ProviderContainer container) {
  container
    ..read(syncSchedulerProvider)
    ..read(logSchedulerProvider);
}

/// BE-B5b: the reminder's plugins, on Android only, before anything
/// schedules. A failure here leaves the reminder to report its own typed
/// reason when it is used; the app starts regardless.
Future<void> _initializeReminderPlugins(ProviderContainer container) async {
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
}
