import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart';
import 'package:memox/features/tags/domain/usecases/watch_tag_catalog_use_case.dart';

import '../../../support/tag_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TAG-001: the use cases of Tag Management hand their arguments to the
// repository unchanged (tag management spec §9).

List<(String, int)> _rows(List<TagCount> counts) => [
  for (final count in counts) (count.name, count.cardCount),
];

void main() {
  late AppDatabase db;
  late TagRepositoryImpl tags;

  setUp(() async {
    db = openTestDatabase();
    tags = TagRepositoryImpl(db, now: () => DateTime(2026, 9, 26));
    await insertTagDecks(db);
    await insertTagCard(db, 'c1');
    await insertTag(db, 't1', 'noun', cardIds: ['c1']);
    await insertTag(db, 't2', 'verb');
  });
  tearDown(() => db.close());

  test('WatchTagCatalogUseCase reads the library under the search '
      '(UC-TAG-001 steps 1-3)', () async {
    final watch = WatchTagCatalogUseCase(tags);

    expect(_rows(await watch().first), [('noun', 1), ('verb', 0)]);
    expect(_rows(await watch(searchTerm: 'NO').first), [('noun', 1)]);
  });

  test('WatchDeckTagCountsUseCase reads every tag in one deck '
      '(UC-TAG-001 step 6)', () async {
    final watch = WatchDeckTagCountsUseCase(tags);

    expect(_rows(await watch(deckId: 'other').first), [
      ('noun', 0),
      ('verb', 0),
    ]);
  });
}
