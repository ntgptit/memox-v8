import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:memox/core/database/connection.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/console_sink.dart';
import 'package:memox/core/logging/log_api.dart';
import 'package:memox/core/logging/log_shipper.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'logging_providers.g.dart';

/// The device's log buffer (ADR-018 §3).
@Riverpod(keepAlive: true)
LogDatabase logDatabase(Ref ref) {
  final db = openLogDatabase();
  ref.onDispose(db.close);
  return db;
}

/// `log_push` through the Supabase project; main.dart has initialized it.
/// It waits for sync's session instead of signing in.
@Riverpod(keepAlive: true)
LogApi logApi(Ref ref) {
  final client = Supabase.instance.client;
  return LogApi(
    ensureSession: existingSessionOnly(
      () => client.auth.currentSession != null,
    ),
    rpc: (function, params) => client.rpc<Object?>(function, params: params),
  );
}

/// Whether the app is in front. Logs ship only then (ADR-018 §3): a push in
/// the background wakes the radio for nothing the owner is waiting on.
/// Injectable, so a test needs no lifecycle.
@Riverpod(keepAlive: true)
bool Function() isForeground(Ref ref) =>
    () => WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

/// Pushes the buffer at start, every [_every] and when the network returns,
/// backing off like sync; null when this build names no Supabase project.
@Riverpod(keepAlive: true)
SyncScheduler? logScheduler(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) return null;
  final shipper = LogShipper(
    ref.watch(logDatabaseProvider),
    ref.watch(logApiProvider),
  );
  final online = Connectivity().onConnectivityChanged
      .where((results) => !results.contains(ConnectivityResult.none))
      .map((_) {});
  final scheduler = startLogScheduler(
    run: shipper.runOnce,
    periodic: Stream<void>.periodic(_every),
    reconnects: online,
    isForeground: ref.watch(isForegroundProvider),
  );
  ref.onDispose(scheduler.dispose);
  return scheduler;
}

/// The log scheduler, started. Both triggers, the periodic push and the
/// reconnect, are dropped unless [isForeground]: the app calls `syncNow` when
/// it resumes, so nothing waits for the next tick.
SyncScheduler startLogScheduler({
  required Future<void> Function() run,
  required Stream<void> periodic,
  required Stream<void> reconnects,
  required bool Function() isForeground,
  Duration debounce = const Duration(seconds: 2),
}) => SyncScheduler(
  run: run,
  triggers: periodic.where((_) => isForeground()),
  reconnects: reconnects.where((_) => isForeground()),
  debounce: debounce,
  // A failed push logs to the console only: into the buffer, it would grow
  // what it failed to empty (ADR-018 §3).
  logger: AppLogger(sinks: const [ConsoleSink()]),
)..start();

const _every = Duration(minutes: 5);
