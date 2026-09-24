import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _host(DeckEntity deck) => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showRenameDeckDialog(context, deck: deck),
    ),
  ),
);

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  libraryTest('rename starts from the current name and saves the new one', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await open(tester);

    expect(find.text('Korean'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect((await env.decks.findById(korean.id))!.name, 'Hàn Quốc');
  });

  libraryTest('a blank name stays in the dialog, under the field', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await open(tester);
    await tester.enterText(find.byType(EditableText), '   ');
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.deckRejectionBlankName), findsOneWidget);
  });

  libraryTest('a deck gone meanwhile closes the dialog and says so (P2-L10)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await open(tester);
    await env.decks.deleteDeck(deckId: korean.id);
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(_en.deckRejectionNotFound), findsOneWidget);
  });
}
