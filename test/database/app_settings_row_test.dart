import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

// BR-SETTINGS-001: the one `app_settings` row exists from the first open, so
// every surface reads real values, never a missing row.

void main() {
  test('a fresh database holds exactly one app_settings row, at the column '
      'defaults', () async {
    final opened = DateTime(2026, 9, 24, 8);
    final db = AppDatabase(NativeDatabase.memory(), now: () => opened);
    addTearDown(db.close);

    final rows = await db.select(db.appSettings).get();

    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.id, 1);
    expect(row.cardLimit, 20);
    expect(row.newCardOrder, 'created');
    expect(row.themeMode, 'system');
    expect(row.language, 'system');
    expect(row.reminderEnabled, 0);
    expect(row.updatedAt, opened);
  });

  test('opening a database again keeps the row it already holds', () async {
    final folder = await Directory.systemTemp.createTemp('memox_settings');
    addTearDown(() => folder.delete(recursive: true));
    final file = File('${folder.path}/memox.sqlite');

    final first = AppDatabase(
      NativeDatabase(file),
      now: () => DateTime(2026, 9, 24),
    );
    await first.customStatement(
      "UPDATE app_settings SET theme_mode = 'dark' WHERE id = 1",
    );
    await first.close();
    final second = AppDatabase(
      NativeDatabase(file),
      now: () => DateTime(2026, 9, 25),
    );
    addTearDown(second.close);

    final row = await second.select(second.appSettings).getSingle();
    expect(row.themeMode, 'dark');
    expect(row.updatedAt, DateTime(2026, 9, 24));
  });

  test('a database file written before the row existed gets it on the next '
      'open, at the defaults', () async {
    final folder = await Directory.systemTemp.createTemp('memox_settings');
    addTearDown(() => folder.delete(recursive: true));
    final file = File('${folder.path}/memox.sqlite');
    final earlier = AppDatabase(NativeDatabase(file));
    await earlier.customStatement('DELETE FROM app_settings');
    await earlier.close();

    final reopened = AppDatabase(
      NativeDatabase(file),
      now: () => DateTime(2026, 9, 25),
    );
    addTearDown(reopened.close);

    final rows = await reopened.select(reopened.appSettings).get();
    expect(rows, hasLength(1));
    expect(rows.single.cardLimit, 20);
    expect(rows.single.themeMode, 'system');
    expect(rows.single.updatedAt, DateTime(2026, 9, 25));
  });
}
