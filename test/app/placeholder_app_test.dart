import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Every route of docs/screens/SCREEN_CATALOG.md → the SCR id its placeholder names
/// (spec 2026-10-04-sp2 §5.2). Ids are arbitrary: a placeholder reads nothing.
const _routes = <String, String>{
  '/decks': 'SCR-DECK-001',
  '/decks/deck/no-such-id': 'SCR-DECK-001 · SCR-CARD-001',
  '/decks/deck/d1/algorithm': 'SCR-SRS-001',
  '/decks/deck/d1/cards/new': 'SCR-CARD-002',
  '/decks/deck/d1/cards/import': 'SCR-TRANSFER-001',
  '/decks/deck/d1/study': 'SCR-STUDY-002',
  '/decks/deck/d1/options': 'SCR-SETTINGS-001',
  '/decks/starter': 'SCR-STARTER-001',
  '/decks/search?q=bap': 'SCR-SEARCH-001',
  '/decks/tags': 'SCR-TAG-001',
  '/decks/trash': 'SCR-TRASH-001',
  '/decks/card/c1': 'SCR-CARD-004',
  '/decks/card/c1/edit': 'SCR-CARD-003',
  '/study': 'SCR-STUDY-001',
  '/study/session/s1': 'SCR-STUDY-003…SCR-STUDY-009',
  '/progress': 'SCR-PROGRESS-001',
  '/progress/d1': 'SCR-PROGRESS-001',
  '/settings': 'SCR-SETTINGS-002',
  '/settings/theme': 'SCR-SETTINGS-003',
  '/settings/language': 'SCR-SETTINGS-004',
  '/settings/reminder': 'SCR-REMINDER-001',
  '/settings/sync': 'SCR-ACCOUNT-001',
  '/settings/sign-in?mode=reauth&from=/study': 'SCR-ACCOUNT-003',
  '/settings/sign-in/code?mode=reauth&email=a@b.c': 'SCR-ACCOUNT-004',
  '/settings/users': 'SCR-ACCOUNT-006',
  '/settings/monitoring': 'SCR-MONITORING-001',
  '/settings/monitoring/x?local=1': 'SCR-MONITORING-001',
};

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

void main() {
  libraryTest(
    'cold start lands on the Library placeholder with the four tabs',
    (tester, env) async {
      await pumpMemoxApp(tester, env);

      expect(find.text('SCR-DECK-001'), findsOneWidget);
      expect(find.text(_en.placeholderBeingRebuilt), findsOneWidget);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations.map((d) => (d as NavigationDestination).label), [
        _en.navLibrary,
        _en.navStudy,
        _en.navProgress,
        _en.navSettings,
      ]);
      expect(bar.selectedIndex, 0);
    },
  );

  libraryTest(
    'a tab tap opens that tab, and a second tap returns it to its root',
    (tester, env) async {
      await pumpMemoxApp(tester, env);

      await tester.tap(find.text(_en.navProgress));
      await tester.pumpAndSettle();
      expect(find.text('SCR-PROGRESS-001'), findsOneWidget);

      _router(tester).go('/progress/d1');
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en.navProgress));
      await tester.pumpAndSettle();
      expect(
        _router(tester).routerDelegate.currentConfiguration.uri.path,
        '/progress',
      );
    },
  );

  libraryTest('every catalog route shows its screen placeholder', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(tester, env);

    for (final entry in _routes.entries) {
      _router(tester).go(entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  libraryTest('an unknown location offers the way back to the Library', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(tester, env);

    _router(tester).go('/nowhere');
    await tester.pumpAndSettle();
    expect(find.text(_en.routeNotFoundTitle), findsOneWidget);
    expect(find.textContaining('/nowhere'), findsNothing);

    await tester.tap(find.text(_en.deckBackToLibrary));
    await tester.pumpAndSettle();
    expect(find.text('SCR-DECK-001'), findsOneWidget);
  });

  libraryTest('welcome placeholder continues to where the launch was headed', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(tester, env);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );

    container.read(welcomeDueProvider.notifier).show();
    _router(tester).go('/progress');
    await tester.pumpAndSettle();
    expect(find.text('SCR-ACCOUNT-002'), findsOneWidget);

    await tester.tap(find.text(_en.accountContinue));
    await tester.pumpAndSettle();
    expect(container.read(welcomeDueProvider), isFalse);
    expect(find.text('SCR-PROGRESS-001'), findsOneWidget);
  });
}
