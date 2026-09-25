import 'package:drift/drift.dart';
import 'package:memox/core/database/schema_versions.dart';

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
  int get schemaVersion => 2;

  /// Each step works on the schema of its own version (`schema_versions.dart`,
  /// generated from `drift_schemas/`), never on today's tables, and a shipped
  /// step never changes (`.claude/skills/flutter-drift/references/
  /// migrations.md`).
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        // Package 2b: the fill hint and the match board on the queue row, and
        // the stored options of a guess question (graded modes spec §6).
        await m.addColumn(
          schema.studyQueueItems,
          schema.studyQueueItems.hintShown,
        );
        await m.addColumn(
          schema.studyQueueItems,
          schema.studyQueueItems.meaningSlot,
        );
        await m.createTable(schema.studyGuessOptions);
        await m.createIndex(schema.idxStudyGuessOptionsOption);
      },
    ),
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
