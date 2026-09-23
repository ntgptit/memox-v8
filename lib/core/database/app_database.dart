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
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
