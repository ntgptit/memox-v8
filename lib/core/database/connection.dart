import 'package:drift_flutter/drift_flutter.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/log/log_database.dart';

AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'memox'));

/// The log buffer (ADR-018 §3): its own file, no tracer.
LogDatabase openLogDatabase() => LogDatabase(driftDatabase(name: 'memox_logs'));
