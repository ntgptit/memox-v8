import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/providers/delete_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/states/library_root_state.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

void main() {
  late LibraryEnv env;
  setUp(() => env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday)));
  tearDown(() => env.db.close());

  /// The states seen so far, with the provider kept alive.
  List<LibraryRootState> watch(ProviderContainer container) {
    final seen = <LibraryRootState>[];
    container.listen(
      libraryRootStateProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );
    return seen;
  }

  final root = deckLevelProvider(
    parentId: null,
    sort: DeckLevelSort.manual,
    filter: DeckLevelFilter.all,
  );

  test('loading, then Empty with no deck', () async {
    final container = libraryContainer(env);
    final seen = watch(container);
    expect(seen.single, isA<LibraryRootLoading>());
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootEmpty>());
    expect(seen.last.hasDecks, isFalse);
  });

  test('a deck makes Decks; losing the last one makes Empty; a new one makes '
      'Decks again (scenarios B and C)', () async {
    final korean = await env.decks.root('Korean');
    final container = libraryContainer(env);
    final seen = watch(container);
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootDecks>());
    expect((seen.last as LibraryRootDecks).level.deckCount, 1);

    await container.read(deleteDeckUseCaseProvider)(deckId: korean.id);
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootEmpty>());

    await env.decks.root('Kanji');
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootDecks>());
  });

  test(
    '"Due only" over decks with nothing due is still Decks (ruling L4)',
    () async {
      await env.decks.root('Korean');
      final container = libraryContainer(env);
      final seen = watch(container);
      await pumpEventQueue();
      container
          .read(deckLevelQueryProvider(null).notifier)
          .show(DeckLevelFilter.due);
      await pumpEventQueue();

      final last = seen.last;
      expect(last, isA<LibraryRootDecks>());
      expect((last as LibraryRootDecks).level.tiles, isEmpty);
    },
  );

  test('a refresh with data stays Decks: the chrome never blinks (Review '
      'Focus 2)', () async {
    await env.decks.root('Korean');
    final container = libraryContainer(env);
    final seen = watch(container);
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootDecks>());

    container.invalidate(root);
    await pumpEventQueue();

    expect(seen.last, isA<LibraryRootDecks>());
    expect(seen.skip(1).whereType<LibraryRootLoading>(), isEmpty);
  });

  test('a failure is Failed, even after data', () async {
    // The root stream delivers a deck, then dies: the chrome must not keep
    // the stale deck's search field over a body that says Retry.
    Stream<DeckLevel> deckThenFailure() async* {
      yield DeckLevel.of([
        DeckTile(
          id: 'korean',
          name: 'Korean',
          siblingPosition: 0,
          createdAt: libraryToday,
          schedulerType: SchedulerType.eightBox,
          subDeckCount: 0,
          cardCount: 0,
          newCount: 0,
          overdueCount: 0,
          dueTodayCount: 0,
          masteredCount: 0,
          oldestDueAt: null,
          startOfToday: libraryToday,
        ),
      ]);
      throw UnknownDatabaseFailure(cause: StateError('read failed'));
    }

    final container = libraryContainer(
      env,
      overrides: [root.overrideWith((ref) => deckThenFailure())],
    );
    final seen = watch(container);
    await pumpEventQueue();

    expect(seen.whereType<LibraryRootDecks>(), hasLength(1));
    expect(seen.last, isA<LibraryRootFailed>());
  });
}
