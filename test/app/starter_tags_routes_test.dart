import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/app_harness.dart';
import '../support/starter_screen_fixtures.dart';
import '../support/tag_fixtures.dart';
import '../support/forui_expect.dart';

import 'package:forui/forui.dart';

// The routes around Starter decks and Tags (FE-B2 + FE-B4 spec D2, D5,
// D11, §5.1).

final _en = lookupAppLocalizations(const Locale('en'));

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

    await tapAndSettle(tester, byControlLabel(_en.libraryStarterDecks));
    expect(barTitle(_en.starterTitle), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
    await tapAndSettle(tester, byControlLabel(_en.commonBack));
    expect(barTitle(_en.navLibrary), findsOneWidget);

    await tapAndSettle(tester, byControlLabel(_en.libraryTags));
    expect(barTitle(_en.tagsTitle), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
    expect(find.text('food'), findsOneWidget);
    await tapAndSettle(tester, byControlLabel(_en.commonBack));
    expect(find.byType(MxBottomNav), findsOneWidget);
  });

  libraryTest('an empty Library browses starter decks; Open lands on the '
      'new deck in the Library (§5.1)', (tester, env) async {
    final library = StarterLibraryFake(env);
    await pumpMemoxApp(tester, env, overrides: [library.asOverride]);

    await tapAndSettle(tester, find.text(_en.libraryBrowseStarterDecks));
    await tapAndSettle(
      tester,
      find.widgetWithText(MxButton, _en.starterAddToLibrary).last,
    );
    await tapAndSettle(tester, find.text(_en.starterAddDeck));
    await tapAndSettle(tester, find.text(_en.starterOpen));

    expect(barTitle(hangulTemplate.title), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);
    await tapAndSettle(tester, byControlLabel(_en.commonBack));
    expect(barTitle(_en.navLibrary), findsOneWidget);
    expect(find.text(hangulTemplate.title), findsOneWidget);
  });

  libraryTest('a build without templates sends "Create a deck" back to the '
      "Library's create dialog", (tester, env) async {
    final library = StarterLibraryFake(env, templates: const []);
    await pumpMemoxApp(tester, env, overrides: [library.asOverride]);

    await tapAndSettle(tester, find.text(_en.libraryBrowseStarterDecks));
    await tapAndSettle(tester, find.text(_en.starterCreateDeck));

    expect(find.byType(MxDialog), findsOneWidget);
    await tapAndSettle(tester, find.text(_en.commonCancel));
    expect(barTitle(_en.navLibrary), findsOneWidget);
  });

  libraryTest('Find cards with this tag opens the Library search on its '
      'name; Back returns to the Library (D11)', (tester, env) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await tapAndSettle(tester, byControlLabel(_en.libraryTags));
    await tapAndSettle(tester, byControlLabel(_en.tagsRowActions('food')));
    await tapAndSettle(tester, find.text(_en.tagsFindCards));
    await tester.pump(searchDebounce);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FTextField, 'food'), findsOneWidget);
    expect(find.text('bap · back'), findsOneWidget);
    await tapAndSettle(tester, byControlLabel(_en.commonBack));
    expect(barTitle(_en.navLibrary), findsOneWidget);
  });
}
