import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/starter_screen_fixtures.dart';
import '../support/tag_fixtures.dart';

// The routes around Starter decks and Tags (FE-B2 + FE-B4 spec D2, D5,
// D11, §5.1).

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Korean › Words with bap, tagged "food".
Future<void> _seed(LibraryEnv env) async {
  final words = await env.decks.sub(
    (await env.decks.root('Korean')).id,
    'Words',
  );
  await insertCard(env.db, id: 'c0', deckId: words.id, front: 'bap');
  await insertTag(env.db, 't-food', 'food', cardIds: ['c0']);
}

void main() {
  libraryTest('the Library app bar opens Starter decks and Tags above the '
      'shell; Back returns (D2, D5)', (tester, env) async {
    await _seed(env);
    final library = StarterLibraryFake(env);
    await pumpMemoxApp(tester, env, overrides: [library.asOverride]);

    await _tap(tester, find.byTooltip(_en.libraryStarterDecks));
    expect(_barTitle(_en.starterTitle), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(_barTitle(_en.navLibrary), findsOneWidget);

    await _tap(tester, find.byTooltip(_en.libraryTags));
    expect(_barTitle(_en.tagsTitle), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
    expect(find.text('food'), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(MxBottomNav), findsOneWidget);
  });

  libraryTest('an empty Library browses starter decks; Open lands on the '
      'new deck in the Library (§5.1)', (tester, env) async {
    final library = StarterLibraryFake(env);
    await pumpMemoxApp(tester, env, overrides: [library.asOverride]);

    await _tap(tester, find.text(_en.libraryBrowseStarterDecks));
    await _tap(
      tester,
      find.widgetWithText(MxButton, _en.starterAddToLibrary).last,
    );
    await _tap(tester, find.text(_en.starterAddDeck));
    await _tap(tester, find.text(_en.starterOpen));

    expect(_barTitle(hangulTemplate.title), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(_barTitle(_en.navLibrary), findsOneWidget);
    expect(find.text(hangulTemplate.title), findsOneWidget);
  });

  libraryTest('a build without templates sends "Create a deck" back to the '
      "Library's create dialog", (tester, env) async {
    final library = StarterLibraryFake(env, templates: const []);
    await pumpMemoxApp(tester, env, overrides: [library.asOverride]);

    await _tap(tester, find.text(_en.libraryBrowseStarterDecks));
    await _tap(tester, find.text(_en.starterCreateDeck));

    expect(find.byType(MxDialog), findsOneWidget);
    await _tap(tester, find.text(_en.commonCancel));
    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });

  libraryTest('Find cards with this tag opens the Library search on its '
      'name; Back returns to the Library (D11)', (tester, env) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.byTooltip(_en.libraryTags));
    await _tap(tester, find.byTooltip(_en.tagsRowActions('food')));
    await _tap(tester, find.text(_en.tagsFindCards));
    await tester.pump(searchDebounce);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'food'), findsOneWidget);
    expect(find.text('bap · back'), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });
}
