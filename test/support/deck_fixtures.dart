import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:memox/core/database/app_database.dart';

/// Decks made through the real repository, so every column is as the app
/// leaves it. A refusal here is a broken fixture, so it throws.
extension DeckFixtures on DeckRepository {
  Future<DeckEntity> root(
    String name, [
    SchedulerType type = SchedulerType.eightBox,
  ]) async => _made(await createRootDeck(name: name, schedulerType: type));

  Future<DeckEntity> sub(String parentId, String name) async =>
      _made(await createSubDeck(parentId: parentId, name: name));
}

DeckEntity _made(Outcome<DeckEntity, DeckRejection> result) => switch (result) {
  Ok(:final value) => value,
  Rejected(:final reason) => throw StateError('fixture deck refused: $reason'),
};

/// Records a first answer on [rootId], which locks its scheduler
/// (BR-SRS-003).
Future<void> lockScheduler(AppDatabase db, String rootId) => db.customUpdate(
  'UPDATE deck SET first_answered_at = ? WHERE id = ?',
  variables: [
    Variable<DateTime>(DateTime(2026, 9, 20)),
    Variable<String>(rootId),
  ],
  updates: {db.deck},
);
