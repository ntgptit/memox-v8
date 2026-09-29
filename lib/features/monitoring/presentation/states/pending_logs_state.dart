import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';

/// The Not sent tab: the levels shown and the device buffer's rows.
@immutable
final class PendingLogsState {
  const PendingLogsState({
    this.levels = LogFilter.defaultLevels,
    this.logs = const AsyncLoading(),
  });

  final Set<LogLevel> levels;
  final AsyncValue<PendingLogs> logs;
}
