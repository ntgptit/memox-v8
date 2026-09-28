import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../support/library_harness.dart';

// IT-NAV-005 (HOST-WIDGET): an unknown route shows a not-found screen in the
// person's language, with no exception text, and a way back to the Library
// (FE-D3 spec D5).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('an unknown route shows not found, no exception text, and Back '
      'to Library opens the Library (IT-NAV-005)', (tester, env) async {
    await pumpMemoxApp(tester, env);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/nowhere');
    await tester.pumpAndSettle();

    expect(find.text(_en.routeNotFoundTitle), findsOneWidget);
    expect(find.text(_en.routeNotFoundBody), findsOneWidget);
    expect(find.textContaining('GoException'), findsNothing);
    expect(find.textContaining('/nowhere'), findsNothing);

    await tester.tap(find.text(_en.deckBackToLibrary));
    await tester.pumpAndSettle();
    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
  });
}
