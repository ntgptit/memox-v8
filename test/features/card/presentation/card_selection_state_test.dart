import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  CardSelection notifier() =>
      container.read(cardSelectionProvider('d').notifier);
  CardSelectionState state() => container.read(cardSelectionProvider('d'));

  test('starts out of selection with nothing picked', () {
    expect(state().isSelecting, isFalse);
    expect(state().ids, isEmpty);
  });

  test('Select cards enters selection with nothing picked (DEV-307)', () {
    notifier().start();
    expect(state().isSelecting, isTrue);
    expect(state().ids, isEmpty);
  });

  test(
    'a long-press toggle enters selection with its card; unticking the '
    'last card keeps the mode until Close',
    () {
      notifier().toggle('c1');
      expect(
        state(),
        isA<CardSelectionState>()
            .having((s) => s.isSelecting, 'isSelecting', isTrue)
            .having((s) => s.ids, 'ids', {'c1'}),
      );
      notifier().toggle('c1');
      expect(state().isSelecting, isTrue);
      expect(state().ids, isEmpty);
      notifier().clear();
      expect(state().isSelecting, isFalse);
    },
  );

  test('select all replaces the picks and stays selecting', () {
    notifier().toggle('c1');
    notifier().selectAll({'c2', 'c3'});
    expect(state().ids, {'c2', 'c3'});
    expect(state().contains('c1'), isFalse);
  });
}
