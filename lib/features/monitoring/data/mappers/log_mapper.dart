import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';

/// The `filter` argument of `log_query` for [filter]. A choice left open is
/// left out: an empty list would match no row (`log_query` counts a list
/// only when it is a JSON array, and an array names what may match).
Map<String, Object?> queryFilterOf(
  LogFilter filter,
  LogCursor? after,
  DateTime now,
) {
  final since = filter.window.since(now);
  return {
    if (filter.levels.isNotEmpty)
      'levels': [for (final level in filter.levels) level.name],
    if (filter.statuses.isNotEmpty)
      'statuses': [for (final status in filter.statuses) status.name],
    if (filter.categories.isNotEmpty)
      'categories': [for (final category in filter.categories) category.name],
    if (filter.search.isNotEmpty) 'search': filter.search,
    if (since != null) 'from': since.toUtc().toIso8601String(),
    if (filter.deviceId case final device?) 'deviceIds': [device],
    'userId': ?filter.userId,
    if (after != null)
      'before': {
        'occurredAt': after.occurredAt.toUtc().toIso8601String(),
        'id': after.id,
      },
    'limit': LogPage.size,
  };
}

/// A compact row of `log_query`.
LogSummaryEntity summaryOfJson(Map<String, Object?> json) => LogSummaryEntity(
  id: json['id']! as String,
  occurredAt: DateTime.parse(json['occurred_at']! as String).toUtc(),
  level: LogLevel.values.byName(json['level']! as String),
  event: json['event']! as String,
  message: json['message'] as String?,
  errorMessage: json['error_message'] as String?,
  errorType: json['error_type'] as String?,
  status: LogStatus.parse(json['status'] as String?),
);

/// A whole row of `app_log`, as `log_get` and `log_set_status` return it
/// (`to_jsonb`, so snake_case and every column).
LogRecordEntity recordOfJson(Map<String, Object?> json) => LogRecordEntity(
  id: json['id']! as String,
  occurredAt: DateTime.parse(json['occurred_at']! as String).toUtc(),
  level: LogLevel.values.byName(json['level']! as String),
  source: json['source'] as String? ?? 'app',
  category: json['category']! as String,
  event: json['event']! as String,
  message: json['message'] as String?,
  errorType: json['error_type'] as String?,
  errorMessage: json['error_message'] as String?,
  stackTrace: json['stack_trace'] as String?,
  context: Map<String, Object?>.from(
    json['context'] as Map<String, Object?>? ?? const {},
  ),
  userId: json['user_id'] as String?,
  deviceId: json['device_id'] as String?,
  appVersion: json['app_version'] as String?,
  buildNumber: json['build_number'] as String?,
  platform: json['platform'] as String?,
  osVersion: json['os_version'] as String?,
  status: LogStatus.parse(json['status'] as String?),
  statusChangedAt: _timeOf(json['status_changed_at']),
  statusChangedBy: json['status_changed_by'] as String?,
  statusNote: json['status_note'] as String?,
);

DateTime? _timeOf(Object? text) =>
    text is String ? DateTime.parse(text).toUtc() : null;

/// A row of the device buffer, as a list shows it: no status, the buffer
/// never holds one.
LogSummaryEntity summaryOfPending(PendingLog row) => LogSummaryEntity(
  id: row.id,
  occurredAt: row.occurredAt,
  level: row.level,
  event: row.event,
  message: row.message,
  errorMessage: row.errorMessage,
  errorType: row.errorType,
);

PendingLogs pendingLogsOf(PendingLogRows rows) => PendingLogs(
  items: [for (final row in rows.items) summaryOfPending(row)],
  total: rows.total,
);

/// A row of the device buffer, whole. It is from this device, so `app`.
LogRecordEntity recordOfEntry(LogEntry entry) => LogRecordEntity(
  id: entry.id,
  occurredAt: entry.occurredAt,
  level: entry.level,
  source: 'app',
  category: entry.category.name,
  event: entry.event,
  message: entry.message,
  errorType: entry.errorType,
  errorMessage: entry.errorMessage,
  stackTrace: entry.stackTrace,
  context: entry.context,
  deviceId: entry.deviceId,
  appVersion: entry.appVersion,
  buildNumber: entry.stamp.buildNumber,
  platform: entry.stamp.platform,
  osVersion: entry.stamp.osVersion,
);
