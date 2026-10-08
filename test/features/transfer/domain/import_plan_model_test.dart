import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_import_target_model.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sections_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

// Spec 2026-10-08 §4.2–§4.4: the groups a preview shows, their
// destinations and the duplicates measured per destination.

const _faces = ColumnMapping({0: TransferField.front, 1: TransferField.back});

CardImportTarget _root({List<CardImportChild> children = const []}) =>
    CardImportTarget(
      holdsCards: false,
      canHoldCards: false,
      hasRoomBelow: true,
      pairs: const {},
      children: children,
    );

ImportPlan _plan(List<List<String>> rows, CardImportTarget target) {
  final table = SourceTable(rows: rows);
  return ImportPlan(
    table: table,
    mapping: _faces,
    hasHeaderRow: true,
    target: target,
    sections: splitSections(table: table, mapping: _faces, hasHeaderRow: true),
  );
}

const _sheet = [
  ['Term', 'Meaning'],
  ['loose', 'x'],
  ['*Part 1', ''],
  ['a', 'b'],
  ['a', 'b'],
  ['*관용어', ''],
  ['c', 'd'],
];

void main() {
  test('groups: the default first, then sections; all new without a clash', () {
    final preview = _plan(
      _sheet,
      _root(),
    ).preview(defaultDeckName: 'Uncategorized', choices: const {});
    expect(preview.isSectioned, isTrue);
    expect(
      [for (final g in preview.groups) (g.name, g.destination)],
      [
        ('Uncategorized', const IntoNewDeck()),
        ('Part 1', const IntoNewDeck()),
        ('관용어', const IntoNewDeck()),
      ],
    );
    // The repeat inside Part 1 is a duplicate of its own section only.
    expect(preview.groups[1].rows.map((r) => r.kind), [
      ImportRowKind.ready,
      ImportRowKind.duplicateInSource,
    ]);
    expect(preview.canCommit, isTrue);
  });

  test('a clash with a deck of cards is undecided until chosen (§4.3)', () {
    final plan = _plan(
      _sheet,
      _root(
        children: [
          const CardImportChild(
            id: 'p1',
            name: 'part 1',
            canHoldCards: true,
            pairs: {(front: 'a', back: 'b')},
          ),
        ],
      ),
    );

    final undecided = plan.preview(
      defaultDeckName: 'Uncategorized',
      choices: const {},
    );
    expect(undecided.groups[1].destination, const Undecided());
    expect((undecided.undecided, undecided.canCommit), (1, false));
    // Shown against the existing deck, as "Add" would see it.
    expect(undecided.groups[1].rows.first.kind, ImportRowKind.duplicateInDeck);

    final added = plan.preview(
      defaultDeckName: 'Uncategorized',
      choices: const {1: ImportSectionChoice.addToExisting},
    );
    expect(added.groups[1].destination, const IntoExistingDeck('p1'));

    final created = plan.preview(
      defaultDeckName: 'Uncategorized',
      choices: const {1: ImportSectionChoice.createNew},
    );
    expect(created.groups[1].destination, const IntoNewDeck());
    expect(created.groups[1].rows.first.kind, ImportRowKind.ready);
  });

  test('a clash with a deck of decks is new without a choice (§4.3)', () {
    final preview = _plan(
      _sheet,
      _root(
        children: [
          const CardImportChild(
            id: 'g',
            name: 'Part 1',
            canHoldCards: false,
            pairs: {},
          ),
        ],
      ),
    ).preview(defaultDeckName: 'Uncategorized', choices: const {});
    expect(preview.groups[1].destination, const IntoNewDeck());
    expect(preview.groups[1].clash!.canHoldCards, isFalse);
    expect(preview.canCommit, isTrue);
  });

  test('the default name: blank, too long, or taken in the file locks the '
      'commit (Review Focus 1)', () {
    final plan = _plan(_sheet, _root());
    ImportNameProblem? problem(String name) => plan
        .preview(defaultDeckName: name, choices: const {})
        .groups
        .first
        .nameProblem;
    expect(problem('  '), ImportNameProblem.blank);
    expect(problem('x' * 201), ImportNameProblem.tooLong);
    expect(problem(' part 1'), ImportNameProblem.takenInFile);
    expect(problem('Misc'), isNull);
    expect(
      plan.preview(defaultDeckName: '', choices: const {}).canCommit,
      isFalse,
    );
  });

  test('a section with a blank name makes its rows invalid '
      '(BR-TRANSFER-015)', () {
    final preview = _plan([
      ['Term', 'Meaning'],
      ['*', ''],
      ['a', 'b'],
    ], _root()).preview(defaultDeckName: 'Uncategorized', choices: const {});
    final row = preview.groups.single.rows.single;
    expect(
      (row.kind, row.deckNameReason),
      (ImportRowKind.invalid, DeckRejection.blankName),
    );
  });

  test('flat into a deck that takes cards: one group, into the target', () {
    final preview = _plan(
      [
        ['Term', 'Meaning'],
        ['a', 'b'],
      ],
      const CardImportTarget(
        holdsCards: true,
        canHoldCards: true,
        hasRoomBelow: true,
        pairs: {},
        children: [],
      ),
    ).preview(defaultDeckName: 'Uncategorized', choices: const {});
    expect(preview.isSectioned, isFalse);
    expect(preview.groups.single.destination, const IntoTarget());
  });

  test('flat into a root: one default group, a new deck', () {
    final preview = _plan([
      ['Term', 'Meaning'],
      ['a', 'b'],
    ], _root()).preview(defaultDeckName: 'Uncategorized', choices: const {});
    expect(preview.isSectioned, isTrue);
    expect(
      [for (final g in preview.groups) (g.name, g.isDefault, g.destination)],
      [('Uncategorized', true, const IntoNewDeck())],
    );
  });
}
