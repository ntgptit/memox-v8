import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_import_target_model.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_sections_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import '../../../support/library_harness.dart';

// The rows of a sectioned preview, grouped by deck (spec 2026-10-08 C1, C3,
// C5).

final _en = lookupAppLocalizations(const Locale('en'));

const _faces = ColumnMapping({0: TransferField.front, 1: TransferField.back});

CardImportDraft _draft({bool hasBlankRow = false}) {
  final table = SourceTable(
    rows: [
      ['Term', 'Meaning'],
      ['*Part 1', ''],
      ['a', '1'],
      ['b', '2'],
      ['c', '3'],
      ['d', '4'],
      ['e', '5'],
      ['a', '1'],
      ['*관용어', ''],
      ['f', '6'],
      if (hasBlankRow) ['', ''],
    ],
  );
  final plan = ImportPlan(
    table: table,
    mapping: _faces,
    hasHeaderRow: true,
    target: const CardImportTarget(
      isDeckOfCards: false,
      canHoldCards: false,
      hasRoomBelow: true,
      pairs: {},
      children: [],
    ),
    sections: splitSections(table: table, mapping: _faces, hasHeaderRow: true),
  );
  return CardImportDraft(
    step: CardImportStep.preview,
    table: table,
    mapping: _faces,
    plan: plan,
    preview: plan.preview(defaultDeckName: 'Uncategorized', choices: const {}),
  );
}

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env, {
  bool hasBlankRow = false,
}) => pumpLibraryScreen(
  tester,
  env,
  Scaffold(
    body: SingleChildScrollView(
      child: ImportPreviewSectionWidget(
        draft: _draft(hasBlankRow: hasBlankRow),
        onIncludeDuplicates: (_) {},
        onChooseSection: (_, _) {},
        onChooseAllSections: (_) {},
        onRenameDefault: (_) {},
        onPreviewAgain: () {},
      ),
    ),
  ),
);

void main() {
  libraryTest('each group is titled with its deck name as typed (C1)', (
    tester,
    env,
  ) async {
    await _pump(tester, env);

    expect(find.text('PART 1'), findsNothing);
    // Once in the Decks block, once over its rows.
    expect(find.text('Part 1'), findsNWidgets(2));
  });

  libraryTest('a deck shows its first 3 rows and how many more (C3)', (
    tester,
    env,
  ) async {
    await _pump(tester, env);

    expect(find.text('c'), findsOneWidget);
    expect(find.text('d'), findsNothing);
    expect(find.text(_en.importRowsMore(3)), findsOneWidget);
    // The next deck still shows its rows.
    expect(find.text('f'), findsOneWidget);
  });

  libraryTest('Include duplicates speaks of each deck (C5)', (
    tester,
    env,
  ) async {
    await _pump(tester, env);

    expect(find.text(_en.importIncludeDuplicatesSectionsBody), findsOneWidget);
    expect(find.text(_en.importIncludeDuplicatesBody), findsNothing);
  });

  // The page surface is 1.18:1 to the tonal neutral pill, under the 1.2 the
  // badge fix holds (DEV-359): the two neutral counts are outlined.
  libraryTest('the duplicate and blank chips are outlined on the page', (
    tester,
    env,
  ) async {
    await _pump(tester, env, hasBlankRow: true);

    final neutral = tester
        .widgetList<MxBadge>(find.byType(MxBadge))
        .where((badge) => badge.tone == MxBadgeTone.neutral)
        .toList();
    expect(neutral.map((badge) => badge.label), [
      _en.importBadgeDuplicate(1),
      _en.importBadgeBlank(1),
    ]);
    expect(neutral.every((badge) => badge.isOutlined), isTrue);
  });
}
