import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/forui_expect.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/deck_screen_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('the sort trigger is named as a sort for TalkBack, with the '
      'order shown (audit 2026-10-17)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    expect(
      byControlLabel(_en.deckSortTrigger(_en.deckSortManual)),
      findsOneWidget,
    );
  });
}
