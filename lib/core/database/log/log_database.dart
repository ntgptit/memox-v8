import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:memox/core/logging/log_entry.dart';

part 'log_database.g.dart';

/// The hard cap of the buffer (spec §3): past it, the oldest `debug` rows go
/// first. Applied at start and after every write (DEV-207).
const int logBufferCap = 50000;

/// How many buffered rows Monitoring lists at most, and how much of a
/// message: the list shows one line.
const int pendingLimit = 200;
const int pendingMessageLength = 300;

/// One buffered row as a list shows it.
final class PendingLog {
  const PendingLog({
    required this.id,
    required this.occurredAt,
    required this.level,
    required this.event,
    this.message,
    this.errorMessage,
    this.errorType,
  });

  final String id;
  final DateTime occurredAt;
  final LogLevel level;
  final String event;

  /// The first [pendingMessageLength] characters of the message and of the
  /// error's message.
  final String? message;
  final String? errorMessage;
  final String? errorType;
}

/// What the buffer holds for a list: the newest rows, and every row's count.
final class PendingLogRows {
  const PendingLogRows({required this.items, required this.total});

  final List<PendingLog> items;
  final int total;
}

/// The device's log buffer (ADR-018 §3): its table, index and queries are
/// `log.drift`'s (ADR-020 D8).
@DriftDatabase(include: {'log.drift'})
class LogDatabase extends _$LogDatabase {
  LogDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  static const _shortLife = Duration(days: 7);
  static const _longLife = Duration(days: 180);

  /// Keeps [entries] in one transaction; an id already here is left as it
  /// is.
  Future<void> insertAll(List<LogEntry> entries) => transaction(() async {
    for (final entry in entries) {
      await insertLogEntry(_companionOf(entry));
    }
  });

  /// The oldest [limit] rows, for a push.
  Future<List<LogEntry>> oldest(int limit) async {
    final rows = await oldestLogRows(limit).get();
    return [for (final row in rows) _entryOf(row)];
  }

  /// The buffer as Monitoring's Not sent tab lists it, again after every
  /// write: the newest [limit] rows of [levels] (every level when it is
  /// empty), each without its stack trace and context (a row's context can
  /// be large), and how many rows wait in all, whatever the level.
  Stream<PendingLogRows> watchPending({
    required Set<LogLevel> levels,
    int limit = pendingLimit,
  }) =>
      pendingLogLines(pendingMessageLength, levels.length, [
        for (final level in levels) level.name,
      ], limit).watch().asyncMap(
        (rows) async => PendingLogRows(
          items: [
            for (final row in rows)
              PendingLog(
                id: row.id,
                occurredAt: DateTime.fromMillisecondsSinceEpoch(
                  row.occurredAt,
                  isUtc: true,
                ),
                level: LogLevel.values.byName(row.level),
                event: row.event,
                message: row.message,
                errorMessage: row.errorMessage,
                errorType: row.errorType,
              ),
          ],
          total: await count(),
        ),
      );

  /// One buffered row whole, or null once it is pushed or pruned.
  Future<LogEntry?> byId(String id) async {
    final row = await logRowById(id).getSingleOrNull();
    return row == null ? null : _entryOf(row);
  }

  Future<void> deleteIds(Iterable<String> ids) => deleteLogRows(ids.toList());

  Future<int> count() => logEntryCount().getSingle();

  /// Drops what the server would drop (ADR-018 §5), then keeps at most [cap]
  /// rows as [pruneExcess] does.
  Future<void> prune({required DateTime now, int cap = logBufferCap}) =>
      transaction(() async {
        await pruneExpiredLogs(
          now.subtract(_shortLife).millisecondsSinceEpoch,
          now.subtract(_longLife).millisecondsSinceEpoch,
        );
        await _dropExcess(cap);
      });

  /// Keeps at most [cap] rows: `debug` goes first, then `info`, `warning`
  /// and `error` last, oldest first within each. The buffer runs it after
  /// every write, so a bulk sync cannot grow the file past the cap between
  /// two pushes (DEV-207).
  Future<void> pruneExcess({int cap = logBufferCap}) =>
      transaction(() => _dropExcess(cap));

  Future<void> _dropExcess(int cap) async {
    final excess = await count() - cap;
    if (excess <= 0) return;
    await pruneLogExcess(excess);
  }

  static LogEntriesCompanion _companionOf(LogEntry entry) =>
      LogEntriesCompanion.insert(
        id: entry.id,
        occurredAt: entry.occurredAt.toUtc().millisecondsSinceEpoch,
        level: entry.level.name,
        category: entry.category.name,
        event: entry.event,
        message: Value(entry.message),
        errorType: Value(entry.errorType),
        errorMessage: Value(entry.errorMessage),
        stackTrace: Value(entry.stackTrace),
        context: Value(_encodeContext(entry.context)),
        deviceId: Value(entry.stamp.deviceId),
        appVersion: Value(entry.stamp.appVersion),
        buildNumber: Value(entry.stamp.buildNumber),
        platform: Value(entry.stamp.platform),
        osVersion: Value(entry.stamp.osVersion),
      );

  static LogEntry _entryOf(LogRow row) => LogEntry(
    id: row.id,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(
      row.occurredAt,
      isUtc: true,
    ),
    level: LogLevel.values.byName(row.level),
    category: LogCategory.values.byName(row.category),
    event: row.event,
    message: row.message,
    errorType: row.errorType,
    errorMessage: row.errorMessage,
    stackTrace: row.stackTrace,
    context: Map<String, Object?>.from(
      jsonDecode(row.context) as Map<String, Object?>,
    ),
    stamp: LogStamp(
      deviceId: row.deviceId,
      appVersion: row.appVersion,
      buildNumber: row.buildNumber,
      platform: row.platform,
      osVersion: row.osVersion,
    ),
  );
}

/// A value JSON cannot encode is stored as its text; a context that cannot be
/// encoded at all (a cycle) as one text field. Either way the entry is kept:
/// one failing entry would otherwise fail every write of its batch.
String _encodeContext(Map<String, Object?> context) {
  try {
    return jsonEncode(context, toEncodable: (value) => value.toString());
  } on Object {
    return jsonEncode({'unencodable': context.toString()});
  }
}
