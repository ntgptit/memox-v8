import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/forui_expect.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import 'support/card_list_section_host.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('after a new request the window grows again: a growth is '
      'asked once per request, not once per screen', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    for (var i = 0; i < 60; i++) {
      await insertCard(
        env.db,
        id: 'c${i.toString().padLeft(2, '0')}',
        deckId: words.id,
        front: 'card $i',
      );
    }
    await pumpLibraryScreen(tester, env, cardListSection(words.id));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CardListSectionWidget)),
    );
    Future<void> scrollToEnd() async {
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pump();
      }
      await tester.pump();
    }

    await scrollToEnd();
    expect(
      container.read(cardListRequestProvider(words.id)).windowSize,
      cardListWindowStep * 2,
    );

    container
        .read(cardListRequestProvider(words.id).notifier)
        .sortBy(CardListSort.dueFirst);
    await tester.pumpAndSettle();
    expect(
      container.read(cardListRequestProvider(words.id)).windowSize,
      cardListWindowStep,
    );
    await scrollToEnd();

    expect(
      container.read(cardListRequestProvider(words.id)).windowSize,
      cardListWindowStep * 2,
    );
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('the sort trigger is named as a sort for TalkBack, with the '
      'order shown (audit 2026-10-17)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'c0', deckId: words.id, front: 'bap');
    await pumpLibraryScreen(tester, env, cardListSection(words.id));

    expect(
      byControlLabel(_en.cardSortTrigger(_en.cardSortNewest)),
      findsOneWidget,
    );
  });
}
