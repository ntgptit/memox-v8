import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/study_route_screens.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/route_naming.dart';
import '../support/study_fixtures.dart';
import '../support/topik_attempt_screen_fixtures.dart';
import '../support/topik_content_fixtures.dart';

// DEV-393 (owner, 2026-10-16): each pushed screen names its route once, so
// TalkBack announces it, as the SDK AppBar does on Android. The `title`
// slot of MxAppBar did since M3F-08; these screens bring their own title.
void main() {
  libraryTest('screen 14, the deck\'s study entry, names its route with the '
      'deck', (tester, env) async {
    final handle = tester.ensureSemantics();
    final root = await env.decks.root('Korean');
    // As the router composes it: the deck feature's header as the title.
    await pumpLibraryScreen(
      tester,
      env,
      Builder(builder: (context) => studyEntryScreen(context, root.id)),
    );
    await tester.pumpAndSettle();

    expect(routeNames(tester), ['Korean']);
    handle.dispose();
  });

  // Opened plain, and with a term as Find cards opens it.
  for (final (name, initialQuery) in const [
    (
      'screen 04, the library search, names its route with its field, as the '
          'SDK AppBar names any title',
      '',
    ),
    (
      'screen 04 opened with a term, as Find cards opens it, still names its '
          'route with its field',
      'verbs',
    ),
  ]) {
    libraryTest(name, (tester, env) async {
      final handle = tester.ensureSemantics();
      await pumpLibraryScreen(
        tester,
        env,
        LibrarySearchScreen(
          onOpenDeck: (_) {},
          onOpenCard: (_) {},
          initialQuery: initialQuery,
        ),
      );
      await tester.pumpAndSettle();

      expect(routeNames(tester), ['Search decks, cards, tags']);
      handle.dispose();
    });
  }

  libraryTest('a study session names its route with its mode', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);
    final opened = await studyEntryRepository(
      env.db,
      env.clock.now,
    ).openLearningSession(deckId: leaf.id);
    final id = (opened as Ok<String, StudyRejection>).value;
    await pumpLibraryScreen(
      tester,
      env,
      StudySessionScreen(
        sessionId: id,
        onDone: (_) {},
        onStudyDeck: (_) {},
        onLeave: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(routeNames(tester), ['Browse']);
    handle.dispose();
  });

  libraryTest('screen 37, a TOPIK attempt, names its route with its mode', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final reading = topikTestFixture();
    final attempt = await topikSeedAttempt(env, reading);
    await pumpTopikAttempt(tester, env, attempt.id, catalog: [reading]);

    expect(routeNames(tester), ['Practice']);
    handle.dispose();
  });
}
