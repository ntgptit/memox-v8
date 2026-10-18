import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// The real card repository on [db], with the real schedule, tag and deck
/// tree collaborators the app wires it with. All of them read the one [now].
///
/// [schedules] and [tags] stand in for a collaborator the test fails or
/// reads on its own.
CardRepositoryImpl cardRepository(
  AppDatabase db, {
  DateTime Function()? now,
  ScheduleRepository? schedules,
  TagRepository? tags,
}) => CardRepositoryImpl(
  db,
  schedules ?? ScheduleRepositoryImpl(db, now: now),
  tags ?? TagRepositoryImpl(db, now: now),
  DeckTreeDataSource(db),
  now: now,
);
