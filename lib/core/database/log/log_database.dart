import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:memox/core/logging/log_entry.dart';

part 'log_database.g.dart';

/// The device's log buffer: rows wait here until `LogShipper` pushes them to
/// `public.app_log` (ADR-018 §3). A table of its own database, so a log write
/// never goes through the app database's tracer or its sync triggers.
@DataClassName('LogRow')
class LogEntries extends Table {
  @override
  String get tableName => 'log_entry';

  TextColumn get id => text()();

  /// Epoch milliseconds, UTC.
  IntColumn get occurredAt => integer()();
  TextColumn get level => text()();
  TextColumn get category => text()();
  TextColumn get event => text()();
  TextColumn get message => text().nullable()();
  TextColumn get errorType => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get stackTrace => text().nullable()();

  /// JSON object.
  TextColumn get context => text().withDefault(const Constant('{}'))();
  TextColumn get deviceId => text().nullable()();
  TextColumn get appVersion => text().nullable()();
  TextColumn get buildNumber => text().nullable()();
  TextColumn get platform => text().nullable()();
  TextColumn get osVersion => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [LogEntries])
class LogDatabase extends _$LogDatabase {
  LogDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await m.createIndex(
        Index(
          'log_entry_occurred_at',
          'CREATE INDEX log_entry_occurred_at ON log_entry (occurred_at)',
        ),
      );
    },
  );

  static const _shortLived = {'debug', 'info'};
  static const _shortLife = Duration(days: 7);
  static const _longLife = Duration(days: 180);

  /// Keeps [entries]; an id already here is left as it is.
  Future<void> insertAll(List<LogEntry> entries) => batch(
    (batch) => batch.insertAll(logEntries, [
      for (final entry in entries) _companionOf(entry),
    ], mode: InsertMode.insertOrIgnore),
  );

  /// The oldest [limit] rows, for a push.
  Future<List<LogEntry>> oldest(int limit) async {
    final rows =
        await (select(logEntries)
              ..orderBy([
                (t) => OrderingTerm.asc(t.occurredAt),
                (t) => OrderingTerm.asc(t.id),
              ])
              ..limit(limit))
            .get();
    return [for (final row in rows) _entryOf(row)];
  }

  Future<void> deleteIds(Iterable<String> ids) =>
      (delete(logEntries)..where((t) => t.id.isIn(ids))).go();

  Future<int> count() async {
    final total = logEntries.id.count();
    return (await (selectOnly(
      logEntries,
    )..addColumns([total])).getSingle()).read(total)!;
  }

  /// Drops what the server would drop (ADR-018 §5), then keeps at most [cap]
  /// rows: `debug` goes first, then `info`, `warning` and `error` last,
  /// oldest first within each.
  Future<void> prune({required DateTime now, int cap = 50000}) =>
      transaction(() async {
        final shortCutoff = now.subtract(_shortLife).millisecondsSinceEpoch;
        final longCutoff = now.subtract(_longLife).millisecondsSinceEpoch;
        await (delete(logEntries)..where(
              (t) =>
                  (t.level.isIn(_shortLived) &
                      t.occurredAt.isSmallerThanValue(shortCutoff)) |
                  (t.level.isNotIn(_shortLived) &
                      t.occurredAt.isSmallerThanValue(longCutoff)),
            ))
            .go();
        final excess = await count() - cap;
        if (excess <= 0) return;
        await customUpdate(
          'DELETE FROM log_entry WHERE id IN ('
          'SELECT id FROM log_entry ORDER BY '
          "CASE level WHEN 'debug' THEN 0 WHEN 'info' THEN 1 ELSE 2 END, "
          'occurred_at, id LIMIT ?)',
          variables: [Variable.withInt(excess)],
          updates: {logEntries},
          updateKind: UpdateKind.delete,
        );
      });

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
        context: Value(jsonEncode(entry.context)),
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
