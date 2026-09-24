import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/screens/deck_search_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

DeckSearchScreen _screen({ValueChanged<String>? onOpenDeck}) =>
    DeckSearchScreen(onOpenDeck: onOpenDeck ?? (_) {});

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
  await tester.pump();
}

void main() {
  libraryTest('a blank term shows nothing', (tester, env) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _screen());
    await _type(tester, '   ');

    expect(find.byType(MxListRow), findsNothing);
    expect(find.byType(MxEmptyState), findsNothing);
  });

  libraryTest('a term finds decks at any depth, each under its path', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, _screen());
    await _type(tester, 'or');

    expect(find.widgetWithText(MxListRow, 'Korean'), findsNWidgets(2));
    expect(find.widgetWithText(MxListRow, 'Words'), findsOneWidget);
    expect(find.text('Kanji'), findsNothing);
  });

  libraryTest('case folds, Vietnamese diacritics included', (
    tester,
    env,
  ) async {
    await env.decks.root('Tiếng Việt');
    await pumpLibraryScreen(tester, env, _screen());
    await _type(tester, 'TIẾNG');

    expect(find.text('Tiếng Việt'), findsOneWidget);
  });

  libraryTest('no hit names the term (ruling P2-L9)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _screen());
    await _type(tester, 'zzz');

    expect(find.text(_en.deckSearchEmptyTitle('zzz')), findsOneWidget);
  });

  libraryTest('a result opens its deck', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final opened = <String>[];
    await pumpLibraryScreen(tester, env, _screen(onOpenDeck: opened.add));
    await _type(tester, 'words');
    await tester.tap(find.text('Words'));

    expect(opened, [words.id]);
  });

  libraryTest('results meet the target guidelines at 2x', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Từ vựng tiếng Hàn rất dài để thử cỡ chữ');
    await pumpLibraryScreen(tester, env, _screen(), textScale: 2);
    await _type(tester, 'từ');

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
