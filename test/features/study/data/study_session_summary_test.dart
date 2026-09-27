import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// D11a: answeredCardCount and turnCount, independent of cardCount and of
// each other (Review Focus 4).

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('answeredCardCount is distinct cards with a turn; turnCount is every '
      'turn, including a comeback (D11a)', () async {
    final decks = DeckRepositoryImpl(db);
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: leaf.id);
    await insertCard(db, id: 'c2', deckId: leaf.id);
    await insertCard(db, id: 'c3', deckId: leaf.id);
    await insertSession(
      db,
      id: 's',
      deckId: leaf.id,
      rootId: root.id,
      status: 'completed',
      endedAt: DateTime(2026, 9, 24, 10),
    );
    await insertQueueItem(
      db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c1',
      position: 0,
      status: 'completed',
    );
    await insertQueueItem(
      db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c2',
      position: 1,
      status: 'completed',
    );
    // c3 was in the queue but never answered (BR-MODE-005: browse commits an
    // AdvanceAnswer turn per swipe, so a card left unswiped has no row).
    await insertQueueItem(
      db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c3',
      position: 2,
      status: 'pending',
    );
    // c1 answered twice (a relearning comeback); c2 once.
    await logReview(
      db,
      id: 'r1',
      cardId: 'c1',
      at: DateTime(2026, 9, 24, 9, 1),
    );
    await logReview(
      db,
      id: 'r2',
      cardId: 'c1',
      at: DateTime(2026, 9, 24, 9, 2),
    );
    await logReview(
      db,
      id: 'r3',
      cardId: 'c2',
      at: DateTime(2026, 9, 24, 9, 3),
    );

    final counts = await StudyViewDao(db)
        .summaryCounts('s', lapseActions: const []);
    expect(counts.cardCount, 3);
    expect(counts.answeredCardCount, 2);
    expect(counts.turnCount, 3);

    final view = await StudySessionViewRepositoryImpl(db)
        .watchSession('s')
        .first;
    expect(view!.summary!.answeredCardCount, 2);
    expect(view.summary!.turnCount, 3);
  });
}
