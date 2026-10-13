import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/database/tracing_interceptor.dart';
import 'package:memox/core/logging/sql_log_switch.dart';

/// Every statement is traced into the log (ADR-018 §3); [sqlLog] turns the
/// per-statement row off (SQL log switch spec §4.2).
AppDatabase openAppDatabase({SqlLogSwitch? sqlLog}) => AppDatabase(
  driftDatabase(name: 'memox')
      .interceptWith(TracingInterceptor(sqlLog: sqlLog)),
);

/// The log buffer (ADR-018 §3): its own file, no tracer.
LogDatabase openLogDatabase() => LogDatabase(driftDatabase(name: 'memox_logs'));
