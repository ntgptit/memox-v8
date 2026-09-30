import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';

/// One row of the list (monitoring spec §3.2): what a row shows and nothing
/// heavier. The server sends the first 300 characters of the message and of
/// the error's message, the device buffer the same.
final class LogSummaryEntity {
  const LogSummaryEntity({
    required this.id,
    required this.occurredAt,
    required this.level,
    required this.event,
    this.message,
    this.errorMessage,
    this.errorType,
    this.status,
  });

  final String id;
  final DateTime occurredAt;
  final LogLevel level;
  final String event;
  final String? message;
  final String? errorMessage;
  final String? errorType;

  /// Null for a debug or info row, and for a row of the device buffer.
  final LogStatus? status;

  /// The row's second line: the message's first line, or else the first line
  /// of the error's message, or else the error's type; null when it has none
  /// of them.
  String? get subtitle {
    for (final text in [message, errorMessage]) {
      final line = text?.trim().split('\n').first.trim();
      if (line != null && line.isNotEmpty) return line;
    }
    final type = errorType?.trim();
    return type == null || type.isEmpty ? null : type;
  }

  LogSummaryEntity withStatus(LogStatus next) => LogSummaryEntity(
    id: id,
    occurredAt: occurredAt,
    level: level,
    event: event,
    message: message,
    errorMessage: errorMessage,
    errorType: errorType,
    status: next,
  );
}
