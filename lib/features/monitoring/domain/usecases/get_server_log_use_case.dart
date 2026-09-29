import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/failures/monitoring_failure.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// The detail of a server log; `Rejected(notFound)` when it is gone.
final class GetServerLogUseCase {
  const GetServerLogUseCase(this._logs);

  final MonitoringRepository _logs;

  Future<Outcome<LogRecordEntity, MonitoringRejection>> call(String id) async {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    final record = await _logs.getServer(id);
    if (record == null) return const Rejected(MonitoringRejection.notFound);
    return Ok(record);
  }
}
