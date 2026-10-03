import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_mapping_row_widget.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import 'card_import_screen_harness.dart';

// The import screen over the real backend and a fake picker (UC-TRANSFER-001,
// IT-NAV-012, IT-CARD-014).
//
// The preview, the results footer and the layout of the mapping.

void main() {
  libraryTest(
    'duplicates are skipped unless included (A4); every row a duplicate locks Import (E3)',
    (tester, env) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      await insertCard(
        env.db,
        id: 'x',
        deckId: deck.id,
        front: 'mul',
        back: 'water',
      );
      await pumpImport(
        tester,
        env,
        deck.id,
        file: csvFile('front,back\nmul,water\n'),
      );
      await tapLabel(tester, enL10n.importSourceFile);
      await tapLabel(tester, enL10n.importReadAction);
      await tapLabel(tester, enL10n.importPreviewAction);

      expect(find.text(enL10n.importRowDuplicateInDeck), findsOneWidget);
      expect(find.text(enL10n.importCaptionNothingToImport), findsOneWidget);

      await tapLabel(tester, enL10n.importIncludeDuplicates);
      expect(find.text(enL10n.importCommitAction(1)), findsOneWidget);
    },
  );

  libraryTest('the results footer is one MxActionPair, outline first', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await pumpImport(
      tester,
      env,
      deck.id,
      file: csvFile('front,back\nmul,water\n'),
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);
    await tapLabel(tester, enL10n.importPreviewAction);
    await tapLabel(tester, enL10n.importCommitAction(1));

    final pair = tester.widget<MxActionPair>(find.byType(MxActionPair));
    expect(pair.leading!.tone, MxButtonTone.outline);
    expect(pair.leading!.label, enL10n.importAnother);
  });
  libraryTest('the deck path steps aside while typing and comes back after '
      '(audit P1)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await pumpImport(tester, env, deck.id);
    await tester.pumpAndSettle();

    expect(find.byType(MxBreadcrumb), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byType(MxBreadcrumb), findsNothing);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byType(MxBreadcrumb), findsOneWidget);
  });

  libraryTest('the mapping rows end their field chips on one edge, with no '
      'arrow wandering between (critique 2026-09-30)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await pumpImport(
      tester,
      env,
      deck.id,
      file: csvFile('front,back,tags\nmul,water,noun\n'),
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);

    expect(find.byIcon(AppIcons.arrowRight), findsNothing);
    final chips = find.byType(MxChipTrigger);
    expect(chips, findsNWidgets(3));
    final rights = {
      for (var i = 0; i < 3; i++) tester.getTopRight(chips.at(i)).dx,
    };
    expect(rights, hasLength(1));
  });

  libraryTest('the file helper can be hidden, and stays hidden '
      '(critique 2026-09-30)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await pumpImport(tester, env, deck.id);
    expect(find.text(enL10n.importHelperBody), findsOneWidget);

    await tester.tap(find.byTooltip(enL10n.commonDismissNote));
    await tester.pumpAndSettle();
    expect(find.text(enL10n.importHelperBody), findsNothing);

    await pumpImport(tester, env, deck.id);
    await tester.pumpAndSettle();
    expect(find.text(enL10n.importHelperBody), findsNothing);
  });

  libraryTest('each column shows its first value, under the header when '
      'there is one (critique 2026-09-30)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await pumpImport(
      tester,
      env,
      deck.id,
      file: csvFile('front,back,tags\nmul,water,noun\n'),
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);
    expect(find.text('mul'), findsOneWidget);
    expect(find.text('water'), findsOneWidget);

    await tester.tap(find.text(enL10n.importHeaderToggle));
    await tester.pumpAndSettle();
    // Without a header the first row is data.
    expect(find.text('front'), findsOneWidget);
  });

  libraryTest('a short or blank sample cell shows no sample', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await pumpImport(
      tester,
      env,
      deck.id,
      file: csvFile('front,back,tags\nmul, \n'),
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);
    expect(find.text('mul'), findsOneWidget);
    // Columns B (a blank cell) and C (a missing one) show only their name
    // and header, no sample line.
    final rows = find.byType(ImportMappingRowWidget);
    for (var i = 1; i < 3; i++) {
      final labels = find.descendant(
        of: rows.at(i),
        matching: find.byType(Column),
      );
      expect(
        find.descendant(of: labels.first, matching: find.byType(Text)),
        findsNWidgets(2),
      );
    }
    expect(tester.takeException(), isNull);
  });

  libraryTest('the file line counts data rows: a header row is not a row '
      '(critique 2026-09-30 part 3b)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await pumpImport(
      tester,
      env,
      deck.id,
      file: csvFile('front,back\nmul,water\nbul,fire\n'),
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);
    expect(find.text(enL10n.importFileRead('CSV', 2, 2)), findsOneWidget);

    await tapLabel(tester, enL10n.importHeaderToggle);
    expect(find.text(enL10n.importFileRead('CSV', 3, 2)), findsOneWidget);
  });

  libraryTest('a headerless file keeps its first row as data and the toggle '
      'still names that row (SP2a 2.24)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await pumpImport(
      tester,
      env,
      deck.id,
      file: csvFile('mul,water\nbul,fire\n'),
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);

    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);
    expect(find.text('mul · water'), findsOneWidget);
    expect(find.text(enL10n.importFileRead('CSV', 2, 2)), findsOneWidget);
  });
}
