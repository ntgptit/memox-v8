import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

StudyEntryScreen _screen(String deckId, {ValueChanged<String>? onReady}) =>
    StudyEntryScreen(
      deckId: deckId,
      deckContext: (id, label) =>
          DeckContextHeaderWidget(deckId: id, currentLabel: label),
      onBackToLibrary: () {},
      onSessionReady: onReady ?? (_) {},
    );

void main() {
  libraryTest('watching the entry writes no session (IT-STUDY-002)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);

    await pumpLibraryScreen(tester, env, _screen(leaf.id));
    await tester.pump();

    final sessions = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM study_session')
        .getSingle();
    expect(sessions.read<int>('n'), 0);
  });

  libraryTest('new and due are two separate counts; nothing starts while no '
      'stage chain is built (IT-STUDY-001, spec §3)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'new1', deckId: leaf.id);
    await insertCard(env.db, id: 'new2', deckId: leaf.id);
    for (final (id, day) in [('due1', 20), ('due2', 22), ('due3', 23)]) {
      await insertCard(
        env.db,
        id: id,
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
      );
    }

    await pumpLibraryScreen(tester, env, _screen(leaf.id));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text(_en.studyEntryComingSoon), findsOneWidget);
  });

  libraryTest('nothing to learn or due shows the positive empty state with '
      'the next due date (E1, BR-STUDY-008)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(
      env.db,
      id: 'c1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
    );

    await pumpLibraryScreen(tester, env, _screen(leaf.id));
    await tester.pump();

    expect(find.text(_en.studyEntryNothingTitle), findsOneWidget);
    expect(find.text(_en.studyEntryNextDue('Sep 30')), findsOneWidget);
  });

  libraryTest("Continue takes up today's in_progress session and hands its "
      'id up (UC-STUDY-001 A3b, BR-STUDY-072)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);
    await insertSession(
      env.db,
      id: 's',
      deckId: leaf.id,
      rootId: root.id,
      startedAt: libraryToday,
    );
    await insertQueueItem(
      env.db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c1',
      position: 0,
    );
    String? ready;

    await pumpLibraryScreen(
      tester,
      env,
      _screen(leaf.id, onReady: (id) => ready = id),
    );
    await tester.pump();
    expect(
      find.text(_en.studyEntryResumeOverline.toUpperCase()),
      findsOneWidget,
    );

    await tester.tap(find.text(_en.studyEntryContinue));
    await tester.pump();
    await tester.pump();

    expect(ready, 's');
    final row = await sessionOf(env.db, 's');
    expect(row.read<String>('status'), 'in_progress');
  });
}
