/// How loud a log is. Ordered: a sink compares levels with [index].
enum LogLevel { debug, info, warning, error }

/// Where in the app a log comes from (spec 2026-09-29-app-logging-design.md
/// §2); `server` is written by the Supabase functions only.
enum LogCategory {
  ui,
  navigation,
  state,
  db,
  sync,
  network,
  reminder,
  lifecycle,
  server,
}

/// What every log on this install carries, set once at start.
final class LogStamp {
  const LogStamp({
    this.deviceId,
    this.appVersion,
    this.buildNumber,
    this.platform,
    this.osVersion,
  });

  final String? deviceId;
  final String? appVersion;
  final String? buildNumber;
  final String? platform;
  final String? osVersion;
}

/// One log record, in the shape `public.app_log` stores it (ADR-018). Nothing
/// is redacted (ADR-018 §1).
final class LogEntry {
  const LogEntry({
    required this.id,
    required this.occurredAt,
    required this.level,
    required this.category,
    required this.event,
    this.message,
    this.errorType,
    this.errorMessage,
    this.stackTrace,
    this.context = const {},
    this.stamp = const LogStamp(),
  });

  factory LogEntry.fromJson(Map<String, Object?> json) => LogEntry(
    id: json['id']! as String,
    occurredAt: DateTime.parse(json['occurredAt']! as String).toUtc(),
    level: LogLevel.values.byName(json['level']! as String),
    category: LogCategory.values.byName(json['category']! as String),
    event: json['event']! as String,
    message: json['message'] as String?,
    errorType: json['errorType'] as String?,
    errorMessage: json['errorMessage'] as String?,
    stackTrace: json['stackTrace'] as String?,
    context: Map<String, Object?>.from(
      (json['context'] as Map<String, Object?>?) ?? const {},
    ),
    stamp: LogStamp(
      deviceId: json['deviceId'] as String?,
      appVersion: json['appVersion'] as String?,
      buildNumber: json['buildNumber'] as String?,
      platform: json['platform'] as String?,
      osVersion: json['osVersion'] as String?,
    ),
  );

  final String id;
  final DateTime occurredAt;
  final LogLevel level;
  final LogCategory category;
  final String event;
  final String? message;
  final String? errorType;
  final String? errorMessage;
  final String? stackTrace;
  final Map<String, Object?> context;
  final LogStamp stamp;

  String? get deviceId => stamp.deviceId;
  String? get appVersion => stamp.appVersion;

  /// The wire shape `log_push` reads (camelCase, as the sync payloads).
  Map<String, Object?> toJson() => {
    'id': id,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'level': level.name,
    'category': category.name,
    'event': event,
    'message': message,
    'errorType': errorType,
    'errorMessage': errorMessage,
    'stackTrace': stackTrace,
    'context': context,
    'deviceId': stamp.deviceId,
    'appVersion': stamp.appVersion,
    'buildNumber': stamp.buildNumber,
    'platform': stamp.platform,
    'osVersion': stamp.osVersion,
  };
}

/// Where a log goes. A sink never throws into the caller: [AppLogger] guards
/// every write.
abstract interface class LogSink {
  void write(LogEntry entry);

  /// Writes what is queued; called when the app pauses.
  Future<void> flush();
}
