import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';

/// One log, whole (monitoring spec §3.3): the detail's read of a server row
/// or of a row of the device buffer.
final class LogRecordEntity {
  const LogRecordEntity({
    required this.id,
    required this.occurredAt,
    required this.level,
    required this.source,
    required this.category,
    required this.event,
    this.message,
    this.errorType,
    this.errorMessage,
    this.stackTrace,
    this.context = const {},
    this.userId,
    this.deviceId,
    this.appVersion,
    this.buildNumber,
    this.platform,
    this.osVersion,
    this.status,
    this.statusChangedAt,
    this.statusChangedBy,
    this.statusNote,
  });

  final String id;
  final DateTime occurredAt;
  final LogLevel level;

  /// `app` or `server`.
  final String source;

  /// The stored code, kept as text: a server newer than this build may hold
  /// a category this build does not know.
  final String category;
  final String event;
  final String? message;
  final String? errorType;
  final String? errorMessage;
  final String? stackTrace;
  final Map<String, Object?> context;
  final String? userId;
  final String? deviceId;
  final String? appVersion;
  final String? buildNumber;
  final String? platform;
  final String? osVersion;
  final LogStatus? status;
  final DateTime? statusChangedAt;
  final String? statusChangedBy;
  final String? statusNote;

  /// Only a warning or an error of the server has a status, and only such a
  /// row can be marked fixed or reopened (ADR-018 §6).
  bool get canTriage => status != null;

  /// Every field, as the Copy action puts it on the clipboard.
  Map<String, Object?> toJson() => {
    'id': id,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'level': level.name,
    'source': source,
    'category': category,
    'event': event,
    'message': message,
    'errorType': errorType,
    'errorMessage': errorMessage,
    'stackTrace': stackTrace,
    'context': context,
    'userId': userId,
    'deviceId': deviceId,
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'platform': platform,
    'osVersion': osVersion,
    'status': status?.name,
    'statusChangedAt': statusChangedAt?.toUtc().toIso8601String(),
    'statusChangedBy': statusChangedBy,
    'statusNote': statusNote,
  };
}
