import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// The Not sent tab: the device buffer's newest rows of [levels] (every level
/// when empty), again after every write.
final class WatchPendingLogsUseCase {
  const WatchPendingLogsUseCase(this._logs);

  final MonitoringRepository _logs;

  Stream<PendingLogs> call(Set<LogLevel> levels) => _logs.watchPending(levels);
}
