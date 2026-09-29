import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';

/// The admin's reads and change of the logs (monitoring spec §4.1). The
/// server calls throw `NotAdminFailure`, `OfflineFailure` or `ServerFailure`;
/// a log that is gone is null.
abstract interface class MonitoringRepository {
  /// The page of `public.app_log` that follows [after] (the first page when
  /// null) for [filter], asked at [now] (the Time filter is relative).
  Future<LogPage> queryServer(
    LogFilter filter,
    LogCursor? after, {
    required DateTime now,
  });

  Future<LogRecordEntity?> getServer(String id);

  /// Marks the warning or error [id] [status], with an optional [note];
  /// returns the row as the server now holds it.
  Future<LogRecordEntity?> setStatus(String id, LogStatus status, String? note);

  /// The device buffer, again after every write.
  Stream<PendingLogs> watchPending(Set<LogLevel> levels);

  Future<LogRecordEntity?> getPending(String id);
}
