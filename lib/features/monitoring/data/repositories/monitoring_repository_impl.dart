import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:memox/features/monitoring/data/mappers/log_mapper.dart';
import 'package:memox/features/monitoring/data/mappers/monitoring_error_mapper.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// The server's logs through the admin RPCs, and the device buffer through
/// [LogDatabase] (which already is the buffer's data access, so no data
/// source stands between them).
final class MonitoringRepositoryImpl implements MonitoringRepository {
  MonitoringRepositoryImpl({required this._remote, required this._local});

  final MonitoringRemoteDataSource _remote;
  final LogDatabase _local;

  @override
  Future<LogPage> queryServer(
    LogFilter filter,
    LogCursor? after, {
    required DateTime now,
  }) => _server(() async {
    final rows = await _remote.query(queryFilterOf(filter, after, now));
    return LogPage(items: [for (final row in rows) summaryOfJson(row)]);
  });

  @override
  Future<LogRecordEntity?> getServer(String id) => _server(() async {
    final row = await _remote.get(id);
    return row == null ? null : recordOfJson(row);
  });

  @override
  Future<LogRecordEntity?> setStatus(
    String id,
    LogStatus status,
    String? note,
  ) => _server(() async {
    final row = await _remote.setStatus(id, status.name, note);
    return row == null ? null : recordOfJson(row);
  });

  @override
  Stream<PendingLogs> watchPending(Set<LogLevel> levels) => _local
      .watchPending(levels: levels)
      .map(pendingLogsOf)
      .mapDatabaseErrors();

  @override
  Future<LogRecordEntity?> getPending(String id) => guardDatabase(() async {
    final entry = await _local.byId(id);
    return entry == null ? null : recordOfEntry(entry);
  });

  /// [body], with any error leaving as the [Failure] of
  /// [mapMonitoringError], with its stack trace.
  Future<T> _server<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapMonitoringError(error), stackTrace);
    }
  }
}
