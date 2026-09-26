import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import 'card_fixtures.dart';
import 'deck_fixtures.dart';
import 'study_fixtures.dart';

/// A sm2 root `Korean` with a leaf `Lesson` holding [cards] learned cards
/// `R1`… due before the harness's day (fronts `term N`, backs `meaning N`,
/// examples `example N`, interval 6), and a review of them in self_assess
/// asked [direction], opened at [now]. Returns the session id.
Future<String> openSelfAssessReview(
  AppDatabase db,
  DeckRepository decks,
  DateTime now, {
  int cards = 2,
  DirectionChoice direction = DirectionChoice.koreanToMeaning,
}) async {
  final root = await decks.root('Korean', SchedulerType.sm2);
  final leaf = await decks.sub(root.id, 'Lesson');
  for (var i = 1; i <= cards; i++) {
    await insertCard(
      db,
      id: 'R$i',
      deckId: leaf.id,
      front: 'term $i',
      back: 'meaning $i',
      example: 'example $i',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 10 + i),
      intervalDays: 6,
    );
  }
  await lockScheduler(db, root.id);
  final opened = await studyEntryRepository(db, () => now).openReviewSession(
    deckId: leaf.id,
    mode: StudyMode.selfAssess,
    direction: direction,
  );
  return (opened as Ok<String, StudyRejection>).value;
}
