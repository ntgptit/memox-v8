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

  test('a long-press toggle enters selection with its card; unticking the '
      'last card keeps the mode until Close', () {
    notifier().toggle('c1');
    expect(
      state(),
      isA<CardSelectionState>()
          .having((s) => s.isSelecting, 'isSelecting', isTrue)
          .having((s) => s.ids, 'ids', {'c1'}),
    );
    notifier().toggle('c2');
    expect(state().ids, {'c1', 'c2'});
    notifier().toggle('c1');
    expect(state().ids, {'c2'});
    notifier().toggle('c2');
    expect(state().isSelecting, isTrue);
    expect(state().ids, isEmpty);
    notifier().clear();
    expect(state().isSelecting, isFalse);
    expect(state().ids, isEmpty);
  });

  test('retain drops the picks that are gone and keeps the mode (audit '
      'CARD-14)', () {
    notifier().selectAll({'c1', 'c2'});
    notifier().retain({'c2', 'c3'}, checked: {'c1', 'c2'});
    expect(state().ids, {'c2'});
    expect(state().isSelecting, isTrue);
    notifier().retain({}, checked: {'c2'});
    expect(state().ids, isEmpty);
    expect(state().isSelecting, isTrue);
  });

  test('retain does not start a selection', () {
    notifier().retain({'c1'}, checked: const {});
    expect(state().isSelecting, isFalse);
  });

  test('retain keeps a pick made while the live ids were read (closing '
      'audit 2026-10-17)', () {
    notifier().selectAll({'c1', 'c2'});
    final checked = state().ids;
    notifier().toggle('c9');
    notifier().retain({'c2'}, checked: checked);
    expect(state().ids, {'c2', 'c9'});
  });

  test('select all replaces the picks and stays selecting', () {
    notifier().toggle('c1');
    notifier().selectAll({'c2', 'c3'});
    expect(state().ids, {'c2', 'c3'});
    expect(state().contains('c1'), isFalse);
  });
}
