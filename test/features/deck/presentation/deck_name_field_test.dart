import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// Owner 2026-10-21 (deck name 32 spec §7): no counter to 25, "n / 32" from
// 26, and over the limit the reason at once and Save locked; nothing is cut.

final _en = lookupAppLocalizations(const Locale('en'));

const _family = '👨‍👩‍👧'; // one character, five code points

Widget _host(DeckEntity deck) => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showRenameDeckDialog(context, deck: deck),
    ),
  ),
);

MxSheetActions _actions(WidgetTester tester) =>
    tester.widget<MxSheetActions>(find.byType(MxSheetActions));

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  for (final c
      in <({String name, String typed, String? counter, bool isTooLong})>[
        (
          name: 'short: no counter',
          typed: 'a' * 25,
          counter: null,
          isTooLong: false,
        ),
        (
          name: 'near: the count from the 26th',
          typed: 'a' * 26,
          counter: '26 / 32',
          isTooLong: false,
        ),
        (
          name: 'at the limit',
          typed: 'a' * 32,
          counter: '32 / 32',
          isTooLong: false,
        ),
        (
          name: 'over: the reason, Save locked',
          typed: 'a' * 33,
          counter: '33 / 32',
          isTooLong: true,
        ),
        (
          name: 'a 40-character paste stays whole',
          typed: 'b' * 40,
          counter: '40 / 32',
          isTooLong: true,
        ),
        (
          name: 'within 32 characters, over 128 code points',
          typed: _family * 26,
          counter: '26 / 32',
          isTooLong: true,
        ),
      ]) {
    libraryTest('the name field, ${c.name}', (tester, env) async {
      final deck = await env.decks.root('Korean');
      await pumpLibraryScreen(tester, env, _host(deck));
      await _open(tester);
      await tester.enterText(find.byType(EditableText), c.typed);
      // The error row animates in (ForUI).
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        c.typed,
      );
      final counter = c.counter;
      if (counter == null) {
        expect(find.textContaining(' / 32'), findsNothing);
      }
      if (counter != null) {
        expect(find.text(counter), findsOneWidget);
      }
      expect(
        find.text(_en.deckRejectionNameTooLong),
        c.isTooLong ? findsOneWidget : findsNothing,
      );
      expect(_actions(tester).onConfirm == null, c.isTooLong);
      expect(tester.takeException(), isNull);
    });
  }

  libraryTest('rename opened on a 40-character name shows it whole, over the '
      'limit, Save locked (Review Focus 3)', (tester, env) async {
    final deck = await env.decks.root('Korean');
    await setDeckNameRaw(env.db, deck.id, 'c' * 40);
    final stored = (await env.decks.findById(deck.id))!;
    await pumpLibraryScreen(tester, env, _host(stored));
    await _open(tester);

    expect(find.text('c' * 40), findsOneWidget);
    expect(find.text('40 / 32'), findsOneWidget);
    expect(find.text(_en.deckRejectionNameTooLong), findsOneWidget);
    expect(_actions(tester).onConfirm, isNull);
  });

  libraryTest('shortening clears the reason and unlocks Save', (
    tester,
    env,
  ) async {
    final deck = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(deck));
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'a' * 33);
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'a' * 20);
    await tester.pumpAndSettle();

    expect(find.text(_en.deckRejectionNameTooLong), findsNothing);
    expect(_actions(tester).onConfirm, isNotNull);
  });
}
