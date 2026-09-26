import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../../support/study_entry_fixtures.dart';
import '../../../../../support/study_fixtures.dart';
import '../../../../screen_audit.dart';

final _en = lookupAppLocalizations(const Locale('en'));

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

Future<String> _session(LibraryEnv env) async {
  final root = await env.decks.root('Korean');
  final leaf = await env.decks.sub(root.id, 'Lesson');
  await insertCard(
    env.db,
    id: 'a',
    deckId: leaf.id,
    front: 'ăn uống',
    back: 'to eat and drink',
    pronunciation: 'an uong',
    example: 'Tôi ăn sáng lúc 7 giờ.',
  );
  await insertCard(env.db, id: 'b', deckId: leaf.id);
  final opened = await studyEntryRepository(
    env.db,
    env.clock.now,
  ).openLearningSession(deckId: leaf.id);
  return (opened as Ok<String, StudyRejection>).value;
}

void main() {
  libraryTest('screen 16, Browse', (tester, env) async {
    final id = await _session(env);
    await auditProductionScreen(
      tester,
      screen: StudySessionScreen,
      pump: (brightness, scale) async {
        await pumpLibraryScreen(
          tester,
          env,
          _screen(id),
          brightness: brightness,
          textScale: scale,
        );
        await tester.pumpAndSettle();
      },
    );
  });

  libraryTest('screen 21, the summary after ✕', (tester, env) async {
    final id = await _session(env);
    await env.sessions.abandonSession(sessionId: id);
    await auditProductionScreen(
      tester,
      screen: StudySessionScreen,
      pump: (brightness, scale) async {
        await pumpLibraryScreen(
          tester,
          env,
          _screen(id),
          brightness: brightness,
          textScale: scale,
        );
        await tester.pumpAndSettle();
        expect(find.text(_en.summaryLeftEarly), findsOneWidget);
      },
    );
  });

  libraryTest('screen 16a, Self-assess revealed with its intervals', (
    tester,
    env,
  ) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await auditProductionScreen(
      tester,
      screen: StudySessionScreen,
      pump: (brightness, scale) async {
        // A fresh tree: the start and the reveal live in widget state.
        await tester.pumpWidget(const SizedBox());
        await pumpLibraryScreen(
          tester,
          env,
          _screen(id),
          brightness: brightness,
          textScale: scale,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_en.studySelfAssessShowAnswer));
        await tester.pumpAndSettle();
        expect(find.text(_en.cardActionGood), findsOneWidget);
      },
    );
  });
}
