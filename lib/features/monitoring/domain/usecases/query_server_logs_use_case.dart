import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// The Server tab's list: a page of the server's logs for [filter], starting
/// after [after] (the first page when null).
final class QueryServerLogsUseCase {
  const QueryServerLogsUseCase(this._logs, this._clock);

  final MonitoringRepository _logs;
  final DayClock _clock;

  Future<LogPage> call(LogFilter filter, {LogCursor? after}) =>
      _logs.queryServer(filter, after, now: _clock.now());
}
