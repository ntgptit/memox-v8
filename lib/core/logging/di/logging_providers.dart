import 'package:flutter/widgets.dart';
import 'package:memox/core/database/connection.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/console_sink.dart';
import 'package:memox/core/logging/log_api.dart';
import 'package:memox/core/logging/log_shipper.dart';
import 'package:memox/core/logging/sql_log_dao.dart';
import 'package:memox/core/logging/sql_log_switch.dart';
import 'package:memox/core/logging/sql_log_switch_feeder.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/network/supabase_client.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logging_providers.g.dart';

/// The device's log buffer (ADR-018 §3).
@Riverpod(keepAlive: true)
LogDatabase logDatabase(Ref ref) {
  final db = openLogDatabase();
  ref.onDispose(db.close);
  return db;
}

/// The tracer's SQL log switch (SQL log switch spec §4.1). The database
/// provider hands it to the tracer; the feeder keeps it equal to the
/// account's row.
@Riverpod(keepAlive: true)
SqlLogSwitch sqlLogSwitch(Ref ref) {
  final sqlLog = SqlLogSwitch();
  ref.onDispose(sqlLog.dispose);
  return sqlLog;
}

/// Keeps [sqlLogSwitch] equal to the account's row (SQL log switch spec
/// §4.3). `startApp` reads it once the database has opened; it lives as long
/// as the container, and a new database (Retry on the recovery screen)
/// rebuilds it.
@Riverpod(keepAlive: true)
SqlLogSwitchFeeder sqlLogSwitchFeeder(Ref ref) {
  final feeder = SqlLogSwitchFeeder(
    target: ref.watch(sqlLogSwitchProvider),
    flags: SqlLogDao(ref.watch(databaseProvider)).watchLogSqlStatements(),
  );
  ref.onDispose(feeder.dispose);
  return feeder;
}

/// `log_push` through the Supabase project; `startApp` has initialized it.
/// It waits for sync's session instead of signing in.
@Riverpod(keepAlive: true)
LogApi logApi(Ref ref) => LogApi(
  ensureSession: existingSessionOnly(hasSupabaseSession),
  rpc: supabaseRpc,
);

/// Whether the app is in front. Logs ship only then (ADR-018 §3): a push in
/// the background wakes the radio for nothing the owner is waiting on.
/// Injectable, so a test needs no lifecycle.
@Riverpod(keepAlive: true)
bool Function() isForeground(Ref ref) =>
    () => isForegroundState(WidgetsBinding.instance.lifecycleState);

/// In front when resumed, and before the first lifecycle event (the app has
/// just started in front).
bool isForegroundState(AppLifecycleState? state) =>
    state == null || state == AppLifecycleState.resumed;

/// Pushes the buffer at start, every [_every] and when the network returns,
/// backing off like sync; null when this build names no Supabase project.
/// It starts here; `startApp` (app_bootstrap.dart) is its only reader and
/// reads it before the account coordinator starts (DEV-176).
@Riverpod(keepAlive: true)
SyncScheduler? logScheduler(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) return null;
  final shipper = LogShipper(
    ref.watch(logDatabaseProvider),
    ref.watch(logApiProvider),
  );
  final scheduler = startLogScheduler(
    run: shipper.runOnce,
    periodic: Stream<void>.periodic(_every),
    // The one reconnect signal, the coordinator's too (DEV-203).
    reconnects: ref.watch(networkStatusProvider).reconnects,
    isForeground: ref.watch(isForegroundProvider),
  );
  ref.onDispose(scheduler.dispose);
  return scheduler;
}

/// The log scheduler, started. Nothing ships unless [isForeground]: both
/// triggers are dropped, and a run that comes due in the background (a retry
/// after a failure) does nothing. The app calls `syncNow` when it resumes, so
/// nothing waits for the next tick.
SyncScheduler startLogScheduler({
  required Future<void> Function() run,
  required Stream<void> periodic,
  required Stream<void> reconnects,
  required bool Function() isForeground,
  Duration debounce = const Duration(seconds: 2),
}) => SyncScheduler(
  run: () => isForeground() ? run() : Future<void>.value(),
  triggers: periodic.where((_) => isForeground()),
  reconnects: reconnects.where((_) => isForeground()),
  debounce: debounce,
  // A failed push logs to the console only: into the buffer, it would grow
  // what it failed to empty (ADR-018 §3).
  logger: AppLogger(sinks: const [ConsoleSink()]),
)..start();

const _every = Duration(minutes: 5);
