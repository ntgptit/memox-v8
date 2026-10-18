import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/route_not_found_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../support/library_harness.dart';

// IT-NAV-005 (audit 2026-10-17): the not-found screen fits a short window.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('in a phone held sideways it scrolls instead of overflowing, '
      'and the way back stays reachable', (tester, env) async {
    tester.view
      ..physicalSize = const Size(800, 360)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLibraryScreen(tester, env, const RouteNotFoundScreen());

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text(_en.deckBackToLibrary),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(_en.deckBackToLibrary), findsOneWidget);
  });
}
