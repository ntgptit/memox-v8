import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_form_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The routes around the Trash (FE-B1).
void main() {
  libraryTest('Move to Trash from the editor returns to the card list with '
      'Undo (FE-B1 D13)', (tester, env) async {
    final words = await env.decks.sub(
      (await env.decks.root('Korean')).id,
      'Words',
    );
    await insertCard(
      env.db,
      id: 'c0',
      deckId: words.id,
      front: 'bap',
      back: 'rice',
    );
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.text('Words'));
    await _tap(tester, find.text('bap'));
    await _tap(tester, find.widgetWithText(MxButton, _en.cardEditAction));
    // An unsaved edit goes with the card: no discard prompt (P6).
    await tester.enterText(find.byType(EditableText).at(1), 'cooked rice');
    await tester.pump();
    // The More card is the editor's last block (kit 09).
    await tester.drag(
      find.byType(CardEditorFormWidget),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(MxButton, _en.cardMoveToTrash));
    expect(find.text(_en.cardDeleteTitle(1)), findsOneWidget);
    await _tap(
      tester,
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.text(_en.cardMoveToTrash),
      ),
    );

    expect(find.text(_en.cardDiscardTitle), findsNothing);
    expect(_barTitle('Words'), findsOneWidget);
    expect(find.text(_en.cardTrashedToast('bap')), findsOneWidget);
    await _tap(tester, find.text(_en.commonUndo));
    expect(find.text('bap'), findsOneWidget);
  });
}
