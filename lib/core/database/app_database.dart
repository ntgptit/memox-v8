import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  include: {
    'package:memox/core/database/tables/deck.drift',
    'package:memox/core/database/tables/card.drift',
    'package:memox/core/database/tables/tags.drift',
    'package:memox/core/database/tables/srs.drift',
    'package:memox/core/database/tables/study.drift',
    'package:memox/core/database/tables/settings.drift',
    'package:memox/core/database/queries/card_queries.drift',
    'package:memox/core/database/queries/deck_queries.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // BR-SETTINGS-001: the one settings row exists from the first open, so
      // every surface reads real values. It changes nothing once it exists.
      await into(appSettings).insert(
        AppSettingsCompanion.insert(
          id: const Value(appSettingsRowId),
          updatedAt: _now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    },
  );
}

/// The id of the one `app_settings` row: `CHECK (id = 1)` keeps the table at
/// this row (BR-SETTINGS-001).
const appSettingsRowId = 1;
