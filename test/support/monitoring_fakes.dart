import 'dart:async';

import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, User;

/// A Supabase session whose account has [role] in `app_metadata`, as the
/// dashboard sets it (ADR-018 §7); no role when null.
Session sessionWithRole(String? role) => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: User(
    id: '00000000-0000-0000-0000-0000000000ad',
    appMetadata: {'role': ?role},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-09-29T00:00:00Z',
  ),
);

final DateTime monitoringNow = DateTime.utc(2026, 9, 29, 12);

/// A list row: `id` in the title's place so a test reads which row is which.
LogSummaryEntity summary(
  String id, {
  LogLevel level = LogLevel.error,
  LogStatus? status = LogStatus.open,
  String? message,
  String? errorMessage,
  String? errorType,
  DateTime? at,
  String? event,
}) => LogSummaryEntity(
  id: id,
  occurredAt: at ?? monitoringNow,
  level: level,
  event: event ?? 'sync.push_failed',
  message: message ?? 'message of $id',
  errorMessage: errorMessage,
  errorType: errorType,
  status: status,
);

/// One page of [count] rows named `<prefix>0`, `<prefix>1`, …, newest first.
LogPage pageOf(int count, {String prefix = 'r'}) => LogPage(
  items: [
    for (var i = 0; i < count; i++)
      summary('$prefix$i', at: monitoringNow.subtract(Duration(minutes: i))),
  ],
);

/// A whole log.
LogRecordEntity record(
  String id, {
  LogLevel level = LogLevel.error,
  LogStatus? status = LogStatus.open,
  String source = 'app',
  String category = 'sync',
  String event = 'sync.push_failed',
  String? message = 'The server refused the push',
  String? errorType = 'PostgrestException',
  String? errorMessage = 'PostgrestException(message: NOT_AUTHENTICATED)',
  String? stackTrace =
      '#0      SyncCoordinator.runOnce (sync_coordinator.dart:42)',
  Map<String, Object?> context = const {'entity': 'deck', 'count': 3},
  String? statusNote,
  String? statusChangedBy,
  DateTime? statusChangedAt,
  String? userId = '00000000-0000-0000-0000-00000000dead',
}) => LogRecordEntity(
  id: id,
  occurredAt: DateTime.utc(2026, 9, 26, 8, 30, 15),
  level: level,
  source: source,
  category: category,
  event: event,
  message: message,
  errorType: errorType,
  errorMessage: errorMessage,
  stackTrace: stackTrace,
  context: context,
  userId: userId,
  deviceId: 'device-1',
  appVersion: '8.0.0',
  buildNumber: '12',
  platform: 'android',
  osVersion: '14',
  status: status,
  statusChangedAt: statusChangedAt,
  statusChangedBy: statusChangedBy,
  statusNote: statusNote,
);

/// One `queryServer` call, answered by the test when it likes.
final class QueryCall {
  QueryCall(this.filter, this.after, this.now);

  final LogFilter filter;
  final LogCursor? after;

  /// The moment the Time filter counts back from.
  final DateTime now;
  final Completer<LogPage> _answer = Completer<LogPage>();

  bool get isAnswered => _answer.isCompleted;

  void answer(LogPage page) => _answer.complete(page);

  void fail(Object error) => _answer.completeError(error);
}

/// Monitoring's repository, driven by the test: a server query waits until
/// the test answers it, so a test can answer two in the other order.
final class FakeMonitoringRepository implements MonitoringRepository {
  final queries = <QueryCall>[];
  final statusChanges = <({String id, LogStatus status, String? note})>[];

  /// A log by id, for [getServer] and [setStatus] to find.
  final servers = <String, LogRecordEntity>{};
  final pendings = <String, LogRecordEntity>{};

  /// Thrown by the next [getServer] and [setStatus] while set.
  Object? readError;
  Object? statusError;

  /// While set, [setStatus] waits for it.
  Completer<void>? statusGate;

  /// While set, [getServer] waits for it.
  Completer<void>? readGate;

  /// Answers every query at once, with this page, while set.
  LogPage? autoPage;

  /// Each `watchPending` call's controller, by the levels asked for.
  final watches =
      <({Set<LogLevel> levels, StreamController<PendingLogs> feed})>[];

  QueryCall get lastQuery => queries.last;

  @override
  Future<LogPage> queryServer(
    LogFilter filter,
    LogCursor? after, {
    required DateTime now,
  }) {
    final call = QueryCall(filter, after, now);
    queries.add(call);
    if (autoPage case final page?) call.answer(page);
    return call._answer.future;
  }

  @override
  Future<LogRecordEntity?> getServer(String id) async {
    if (readGate case final gate?) await gate.future;
    if (readError case final error?) throw error;
    return servers[id];
  }

  @override
  Future<LogRecordEntity?> setStatus(
    String id,
    LogStatus status,
    String? note,
  ) async {
    statusChanges.add((id: id, status: status, note: note));
    if (statusGate case final gate?) await gate.future;
    if (statusError case final error?) throw error;
    final row = servers[id];
    if (row == null) return null;
    final changed = record(
      id,
      level: row.level,
      status: status,
      statusNote: note,
      statusChangedBy: 'admin-1',
      statusChangedAt: monitoringNow,
    );
    servers[id] = changed;
    return changed;
  }

  @override
  Stream<PendingLogs> watchPending(Set<LogLevel> levels) {
    final feed = StreamController<PendingLogs>();
    watches.add((levels: levels, feed: feed));
    return feed.stream;
  }

  @override
  Future<LogRecordEntity?> getPending(String id) async => pendings[id];
}
