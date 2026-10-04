import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

ProviderContainer _container(AppDatabase db) {
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<List<String>> names(
    ProviderContainer container, {
    DeckLevelSort sort = DeckLevelSort.manual,
    DeckLevelFilter filter = DeckLevelFilter.all,
  }) async {
    final provider = deckLevelProvider(sort: sort, filter: filter);
    container.listen(provider, (_, _) {});
    final level = await container.read(provider.future);
    return [for (final tile in level.tiles) tile.name];
  }

  test('the roots arrive as one level, in manual order', () async {
    final decks = DeckRepositoryImpl(db);
    await decks.root('Korean');
    await decks.root('Kanji');

    expect(await names(_container(db)), ['Korean', 'Kanji']);
  });

  test('sort and filter reach the use case', () async {
    final decks = DeckRepositoryImpl(db);
    final korean = await decks.root('b Korean');
    await decks.root('A Kanji');
    final words = await decks.sub(korean.id, 'Words');
    await insertCard(
      db,
      id: 'due',
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 24),
    );
    final container = _container(db);

    expect(await names(container, sort: DeckLevelSort.name), [
      'A Kanji',
      'b Korean',
    ]);
    expect(await names(container, filter: DeckLevelFilter.due), ['b Korean']);
  });

  test('the level query starts manual and all, and changes on demand', () {
    final container = _container(db);
    final notifier = container.read(deckLevelQueryProvider(null).notifier);

    expect(
      container.read(deckLevelQueryProvider(null)).sort,
      DeckLevelSort.manual,
    );
    notifier
      ..sortBy(DeckLevelSort.due)
      ..show(DeckLevelFilter.due);
    final query = container.read(deckLevelQueryProvider(null));
    expect(
      (query.sort, query.filter),
      (DeckLevelSort.due, DeckLevelFilter.due),
    );
  });
}
