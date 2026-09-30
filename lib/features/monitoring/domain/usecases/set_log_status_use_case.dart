import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/failures/monitoring_failure.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// Marks a warning or error fixed, or reopens it (ADR-018 §6). A blank note
/// is no note; `Rejected(notFound)` when the log is gone.
final class SetLogStatusUseCase {
  const SetLogStatusUseCase(this._logs);

  final MonitoringRepository _logs;

  Future<Outcome<LogRecordEntity, MonitoringRejection>> call(
    String id,
    LogStatus status, {
    String? note,
  }) async {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    final trimmed = note?.trim();
    final record = await _logs.setStatus(
      id,
      status,
      trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
    if (record == null) return const Rejected(MonitoringRejection.notFound);
    return Ok(record);
  }
}
