import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/di/study_session_repository_provider.dart'
    show studySessionRepositoryProvider;
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/controllers/study_home_controller.dart';
import 'package:memox/features/study/presentation/states/study_home_resume_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// Screen 13's Resume (UC-STUDY-002, FE-A8 H3): the one write of Study Home.

final _now = DateTime(2026, 9, 24, 9);

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = openTestDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(FakeDayClock(_now)),
        studySessionRepositoryProvider.overrideWithValue(
          studySessionRepository(db, () => _now),
        ),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// A learning session opened at [openedAt] on a deck of two new cards.
  Future<String> session(DateTime openedAt) async {
    final decks = DeckRepositoryImpl(db, now: () => openedAt);
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'a', deckId: leaf.id, back: 'a');
    await insertCard(db, id: 'b', deckId: leaf.id, back: 'b');
    final opened = await studyEntryRepository(
      db,
      () => openedAt,
    ).openLearningSession(deckId: leaf.id);
    return (opened as Ok<String, StudyRejection>).value;
  }

  StudyHomeController controller() {
    container.listen(studyHomeControllerProvider, (_, _) {});
    return container.read(studyHomeControllerProvider.notifier);
  }

  test("today's session is taken up, and nothing runs after", () async {
    final id = await session(_now);

    final result = await controller().resume(id);

    expect(result, isA<ResumeOpened>());
    expect((result! as ResumeOpened).sessionId, id);
    expect(container.read(studyHomeControllerProvider), isFalse);
  });

  test('a second Resume while one runs is dropped (BR-STUDY-004)', () async {
    final id = await session(_now);
    final home = controller();

    final results = await Future.wait([home.resume(id), home.resume(id)]);

    expect(results.whereType<ResumeOpened>(), hasLength(1));
    expect(results.where((result) => result == null), hasLength(1));
  });

  test("yesterday's session is refused; Study Home is ready again", () async {
    final id = await session(DateTime(2026, 9, 23, 20));

    final result = await controller().resume(id);

    expect(result, isA<ResumeRefused>());
    expect(container.read(studyHomeControllerProvider), isFalse);
  });
}
