import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';

void main() {
  test('a request starts with every card, newest first, one window', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final request = container.read(cardListRequestProvider('d'));

    expect(
      (request.filter, request.sort, request.searchTerm, request.windowSize),
      (CardListFilter.all, CardListSort.newest, '', cardListWindowStep),
    );
  });

  test('growing adds a window; a new filter or term starts again', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = cardListRequestProvider('d');
    final keep = container.listen(provider, (_, _) {});
    addTearDown(keep.close);
    final notifier = container.read(provider.notifier);

    notifier.grow();
    expect(container.read(provider).windowSize, 2 * cardListWindowStep);
    notifier.show(CardListFilter.due);
    expect(container.read(provider).windowSize, cardListWindowStep);
    notifier
      ..grow()
      ..search('kor');
    expect(container.read(provider).windowSize, cardListWindowStep);
    expect(container.read(provider).query.searchTerm, 'kor');
    expect(container.read(provider).query.filter, CardListFilter.due);
  });

  test('tags filter the query; applying them starts again from the first '
      'window and every other change keeps them (BR-TAG-004)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = cardListRequestProvider('d');
    final keep = container.listen(provider, (_, _) {});
    addTearDown(keep.close);
    final notifier = container.read(provider.notifier);

    notifier
      ..show(CardListFilter.due)
      ..grow()
      ..filterTags({'t1', 't2'});
    expect(container.read(provider).windowSize, cardListWindowStep);
    expect(container.read(provider).query.tagIds, {'t1', 't2'});
    expect(container.read(provider).query.filter, CardListFilter.due);
    notifier
      ..search('kor')
      ..sortBy(CardListSort.dueFirst)
      ..show(CardListFilter.all)
      ..grow();
    expect(container.read(provider).tags, const CardTagFilter({'t2', 't1'}));
    notifier.filterTags(const {});
    expect(container.read(provider).tags.isEmpty, isTrue);
  });

  test('a selection toggles, takes a whole set, and clears', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = cardSelectionProvider('d');
    final keep = container.listen(provider, (_, _) {});
    addTearDown(keep.close);
    final notifier = container.read(provider.notifier);

    notifier
      ..toggle('a')
      ..toggle('b')
      ..toggle('a');
    expect(container.read(provider), {'b'});
    notifier.selectAll({'a', 'b', 'c'});
    expect(container.read(provider), {'a', 'b', 'c'});
    notifier.clear();
    expect(container.read(provider), isEmpty);
  });
}
