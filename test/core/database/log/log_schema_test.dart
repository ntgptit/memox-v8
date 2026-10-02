import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';

/// The log table a fresh install creates is the one installed devices already
/// hold at schema version 1, column for column and index for index: moving its
/// declaration to `log.drift` (ADR-020 D8) must not change it, since there is
/// no migration.
void main() {
  late LogDatabase db;

  setUp(() => db = LogDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<Map<String, Object?>>> pragma(String statement) async => [
    for (final row in await db.customSelect(statement).get()) row.data,
  ];

  test('log_entry keeps its columns, types, nulls, default and key', () async {
    final columns = await pragma('PRAGMA table_info(log_entry)');
    expect(
      [
        for (final c in columns)
          (c['name'], c['type'], c['notnull'], c['dflt_value'], c['pk']),
      ],
      [
        ('id', 'TEXT', 1, null, 1),
        ('occurred_at', 'INTEGER', 1, null, 0),
        ('level', 'TEXT', 1, null, 0),
        ('category', 'TEXT', 1, null, 0),
        ('event', 'TEXT', 1, null, 0),
        ('message', 'TEXT', 0, null, 0),
        ('error_type', 'TEXT', 0, null, 0),
        ('error_message', 'TEXT', 0, null, 0),
        ('stack_trace', 'TEXT', 0, null, 0),
        ('context', 'TEXT', 1, "'{}'", 0),
        ('device_id', 'TEXT', 0, null, 0),
        ('app_version', 'TEXT', 0, null, 0),
        ('build_number', 'TEXT', 0, null, 0),
        ('platform', 'TEXT', 0, null, 0),
        ('os_version', 'TEXT', 0, null, 0),
      ],
    );
  });

  test('log_entry keeps its occurred_at index and its primary key', () async {
    final indexes = await pragma('PRAGMA index_list(log_entry)');
    expect(
      {for (final i in indexes) (i['name'], i['unique'], i['origin'])},
      {
        ('log_entry_occurred_at', 0, 'c'),
        ('sqlite_autoindex_log_entry_1', 1, 'pk'),
      },
    );
    final columns = await pragma('PRAGMA index_info(log_entry_occurred_at)');
    expect([for (final c in columns) c['name']], ['occurred_at']);
  });
}
