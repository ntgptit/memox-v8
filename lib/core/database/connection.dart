import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/database/tracing_interceptor.dart';

/// Every statement is traced into the log (ADR-018 §3).
AppDatabase openAppDatabase() => AppDatabase(
  driftDatabase(name: 'memox').interceptWith(TracingInterceptor()),
);

/// The log buffer (ADR-018 §3): its own file, no tracer.
LogDatabase openLogDatabase() => LogDatabase(driftDatabase(name: 'memox_logs'));
