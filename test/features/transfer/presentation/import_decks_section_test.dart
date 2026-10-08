import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_import_target_model.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sections_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_decks_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';

// The Decks block of a sectioned preview (spec 2026-10-08 U2–U4).

final _en = lookupAppLocalizations(const Locale('en'));

const _faces = ColumnMapping({0: TransferField.front, 1: TransferField.back});

const _sheet = [
  ['Term', 'Meaning'],
  ['loose', 'x'],
  ['*Part 1', ''],
  ['a', 'b'],
];

ImportPreview _preview({
  bool canHoldCards = true,
  String defaultName = 'Uncategorized',
  Map<int, ImportSectionChoice> choices = const {},
}) {
  const table = SourceTable(rows: _sheet);
  return ImportPlan(
    table: table,
    mapping: _faces,
    hasHeaderRow: true,
    target: CardImportTarget(
      isDeckOfCards: false,
      canHoldCards: false,
      hasRoomBelow: true,
      pairs: const {},
      children: [
        CardImportChild(
          id: 'p1',
          name: 'Part 1',
          canHoldCards: canHoldCards,
          cardCount: 42,
          pairs: const {},
        ),
      ],
    ),
    sections: splitSections(table: table, mapping: _faces, hasHeaderRow: true),
  ).preview(defaultDeckName: defaultName, choices: choices);
}

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  ImportPreview preview, {
  void Function(int, ImportSectionChoice)? onChoose,
  ValueChanged<ImportSectionChoice>? onChooseAll,
}) => pumpLibraryScreen(
  tester,
  env,
  Scaffold(
    body: SingleChildScrollView(
      child: ImportDecksSectionWidget(
        preview: preview,
        isIncludingDuplicates: false,
        onChoose: onChoose ?? (_, _) {},
        onChooseAll: onChooseAll ?? (_) {},
        onRename: (_) {},
      ),
    ),
  ),
);

void main() {
  libraryTest('a clash shows the tray with nothing chosen; a tap chooses '
      '(U3)', (tester, env) async {
    final chosen = <(int, ImportSectionChoice)>[];
    await _pump(
      tester,
      env,
      _preview(),
      onChoose: (index, choice) => chosen.add((index, choice)),
    );

    expect(find.text(_en.importDeckClashNote('Part 1', 42)), findsOneWidget);
    // Undecided is neither New nor Existing: only the default deck is New.
    expect(find.text(_en.importDeckNew), findsOneWidget);
    expect(find.text(_en.importDeckExisting), findsNothing);
    await tester.tap(find.text(_en.importDeckAddToExisting));
    expect(chosen, [(1, ImportSectionChoice.addToExisting)]);
  });

  libraryTest('a clash with a deck of decks shows its note and no tray '
      '(§4.3)', (tester, env) async {
    await _pump(tester, env, _preview(canHoldCards: false));

    expect(find.text(_en.importDeckHoldsDecksNote), findsOneWidget);
    expect(find.text(_en.importDeckAddToExisting), findsNothing);
  });

  libraryTest('an empty existing deck is named without "0 cards" (audit)', (
    tester,
    env,
  ) async {
    expect(_en.importDeckClashNote('Idioms', 0), isNot(contains('0')));
  });

  libraryTest('the default deck name is a field; a taken name shows its '
      'error (U4)', (tester, env) async {
    await _pump(tester, env, _preview(defaultName: 'part 1'));

    expect(find.text(_en.importDeckNameLabel), findsOneWidget);
    expect(find.text(_en.importDeckNameTaken), findsOneWidget);
  });

  libraryTest('each deck says New or Existing and its cards', (
    tester,
    env,
  ) async {
    await _pump(
      tester,
      env,
      _preview(choices: const {1: ImportSectionChoice.addToExisting}),
    );

    expect(find.text(_en.importDeckExisting), findsOneWidget);
    expect(find.text(_en.importDeckNew), findsOneWidget);
    expect(find.text(_en.importDeckCards(1)), findsNWidgets(2));
  });

  libraryTest('a chosen clash states what happens (C4)', (tester, env) async {
    await _pump(
      tester,
      env,
      _preview(choices: const {1: ImportSectionChoice.createNew}),
    );
    expect(
      find.text(_en.importDeckCreateConsequence('Part 1')),
      findsOneWidget,
    );

    await _pump(
      tester,
      env,
      _preview(choices: const {1: ImportSectionChoice.addToExisting}),
    );
    expect(find.text(_en.importDeckAddConsequence), findsOneWidget);
  });

  libraryTest('two clashes add a row that decides them all (C2)', (
    tester,
    env,
  ) async {
    const table = SourceTable(
      rows: [
        ['Term', 'Meaning'],
        ['*A', ''],
        ['a', 'b'],
        ['*B', ''],
        ['c', 'd'],
      ],
    );
    final preview = ImportPlan(
      table: table,
      mapping: _faces,
      hasHeaderRow: true,
      target: const CardImportTarget(
        isDeckOfCards: false,
        canHoldCards: false,
        hasRoomBelow: true,
        pairs: {},
        children: [
          CardImportChild(
            id: 'a',
            name: 'A',
            canHoldCards: true,
            cardCount: 1,
            pairs: {},
          ),
          CardImportChild(
            id: 'b',
            name: 'B',
            canHoldCards: true,
            cardCount: 1,
            pairs: {},
          ),
        ],
      ),
      sections: splitSections(
        table: table,
        mapping: _faces,
        hasHeaderRow: true,
      ),
    ).preview(defaultDeckName: 'Uncategorized', choices: const {});
    final all = <ImportSectionChoice>[];
    await _pump(tester, env, preview, onChooseAll: all.add);

    expect(find.text(_en.importDecksTakenNames(2)), findsOneWidget);
    await tester.tap(find.text(_en.importDeckAddAll));
    expect(all, [ImportSectionChoice.addToExisting]);
  });

  libraryTest('one clash adds no row for all', (tester, env) async {
    await _pump(tester, env, _preview());
    expect(find.text(_en.importDeckAddAll), findsNothing);
  });
}
