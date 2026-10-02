import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/progress_screen_fixtures.dart';

// Screen 22's levels in the app (FE-A9 D1, D4, D5; UC-PROGRESS-002 step 5).

final _en = lookupAppLocalizations(const Locale('en'));

Finder _tab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openRow(WidgetTester tester, String name) async {
  final row = find.widgetWithText(MxListRow, name);
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await _tap(tester, row);
}

/// Korean › Grammar › Particles, each studied today.
Future<void> _tree(LibraryEnv env) async {
  final korean = await studiedDeck(
    env,
    'Korean',
    days: [(daysAgo: 0, learning: 0, reviewing: 2)],
  );
  final grammar = await env.decks.sub(korean, 'Grammar');
  await env.decks.sub(grammar.id, 'Particles');
}

void main() {
  libraryTest('a row opens its level under the tab bar, keeping the range; '
      'Back climbs one level (D4, D5)', (tester, env) async {
    await _tree(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, _tab(_en.navProgress));
    await tester.scrollUntilVisible(find.text(_en.progressRangeMonth), 200);
    await _tap(tester, find.text(_en.progressRangeMonth));

    await _openRow(tester, 'Korean');

    expect(find.byType(DeckProgressScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);
    expect(find.text(_en.progressSubDecks.toUpperCase()), findsOneWidget);

    await _openRow(tester, 'Grammar');
    expect(
      find.descendant(
        of: find.byType(MxAppBar),
        matching: find.text('Grammar'),
      ),
      findsOneWidget,
    );

    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(
      find.descendant(of: find.byType(MxAppBar), matching: find.text('Korean')),
      findsOneWidget,
    );
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(find.byType(DeckProgressScreen), findsNothing);
  });

  libraryTest("the path's Progress segment returns to the library level", (
    tester,
    env,
  ) async {
    await _tree(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, _tab(_en.navProgress));
    await _openRow(tester, 'Korean');
    await _openRow(tester, 'Grammar');

    await _tap(
      tester,
      find.descendant(
        of: find.byType(MxBreadcrumb),
        matching: find.text(_en.progressTitle),
      ),
    );

    expect(find.byType(DeckProgressScreen), findsNothing);
    expect(find.byType(ProgressScreen), findsOneWidget);
  });

  libraryTest('Start studying opens the Study tab (D1)', (tester, env) async {
    await studiedDeck(env, 'Korean');
    await pumpMemoxApp(tester, env);
    await _tap(tester, _tab(_en.navProgress));

    await _tap(tester, find.text(_en.progressStartStudying));

    expect(find.byType(StudyHomeScreen), findsOneWidget);
  });
}
