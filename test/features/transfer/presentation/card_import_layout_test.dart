import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';
import 'support/import_screen_helpers.dart';
import 'support/words_deck.dart';

// Screen 11's layout: the duplicates toggle before the rows, one surface at
// the source (critique 2026-09-30 part 3d-2, E10).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('the duplicates toggle comes before the rows (critique '
      '2026-09-30 part 3d-2, E10)', (tester, env) async {
    final deck = await seedWordsDeck(env);
    await insertCard(
      env.db,
      id: 'x',
      deckId: deck.id,
      front: 'mul',
      back: 'water',
    );
    await pumpImportScreen(
      tester,
      env,
      deck.id,
      file: importFile('front,back\nmul,water\nbul,fire\n'),
    );
    await tapImportLabel(tester, _en.importSourceFile);
    await tapImportLabel(tester, _en.importReadAction);
    await tapImportLabel(tester, _en.importPreviewAction);

    expect(
      tester.getTopLeft(find.text(_en.importIncludeDuplicates)).dy,
      lessThan(tester.getTopLeft(find.byType(ImportPreviewRowWidget).first).dy),
    );
  });

  libraryTest('the source step draws one surface and names the formats once '
      '(critique 2026-09-30 part 3d-2, E10)', (tester, env) async {
    final deck = await seedWordsDeck(env);
    await pumpImportScreen(tester, env, deck.id);

    expect(
      find.ancestor(
        of: find.byType(MxEmptyState),
        matching: find.byType(MxCard),
      ),
      findsNothing,
    );
    expect(find.text(_en.importPickBody), findsOneWidget);
    expect(_en.importPickBody, isNot(contains('csv')));
  });
}
