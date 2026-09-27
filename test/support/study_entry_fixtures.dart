import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
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

/// A sm2 root `Korean` > `Lesson` with [newCards] new cards `n0`… and
/// [dueCards] learned cards `d0`… due before the harness's day. Returns the
/// leaf's id.
Future<String> sm2Leaf(
  AppDatabase db,
  DeckRepository decks, {
  int newCards = 0,
  int dueCards = 0,
}) async {
  final root = await decks.root('Korean', SchedulerType.sm2);
  final leaf = await decks.sub(root.id, 'Lesson');
  for (var i = 0; i < newCards; i++) {
    await insertCard(db, id: 'n$i', deckId: leaf.id, back: 'new $i');
  }
  for (var i = 0; i < dueCards; i++) {
    await insertCard(
      db,
      id: 'd$i',
      deckId: leaf.id,
      back: 'due $i',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
  }
  if (dueCards > 0) await lockScheduler(db, root.id);
  return leaf.id;
}

/// The app's entry store; a test sets [isFailing] to make an opening fail as
/// a broken write does (screen 14 startFailed), and reads [opened].
final class FailingEntries implements StudyEntryRepository {
  FailingEntries(this._inner);

  final StudyEntryRepository _inner;
  var isFailing = false;

  /// The openings that reached the store.
  var opened = 0;

  /// When set, an opening waits for it: the screen's starting state.
  Future<void>? gate;

  @override
  Future<Outcome<String, StudyRejection>> openLearningSession({
    required String deckId,
    DateTime? now,
  }) async {
    opened++;
    await gate;
    if (isFailing) throw const UnknownDatabaseFailure(cause: 'test');
    return _inner.openLearningSession(deckId: deckId, now: now);
  }

  @override
  Future<Outcome<String, StudyRejection>> openReviewSession({
    required String deckId,
    required StudyMode mode,
    DirectionChoice? direction,
    DateTime? now,
  }) async {
    opened++;
    await gate;
    if (isFailing) throw const UnknownDatabaseFailure(cause: 'test');
    return _inner.openReviewSession(
      deckId: deckId,
      mode: mode,
      direction: direction,
      now: now,
    );
  }

  @override
  Stream<StudyEntry?> watchEntry({
    required String deckId,
    required DateTime now,
  }) => _inner.watchEntry(deckId: deckId, now: now);
}

/// A review in [mode] of the five due cards of [insertFiveDue] (`ST-01`…
/// `ST-05`, backs apple … elder), opened at [now]. Returns the session id.
Future<String> openFiveDueReview(
  AppDatabase db,
  DeckRepository decks,
  DateTime now,
  StudyMode mode,
) async {
  final leaf = await insertFiveDue(db, decks);
  final opened = await studyEntryRepository(
    db,
    () => now,
  ).openReviewSession(deckId: leaf.id, mode: mode);
  return (opened as Ok<String, StudyRejection>).value;
}
