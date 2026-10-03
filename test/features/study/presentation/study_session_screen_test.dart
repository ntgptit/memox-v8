import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study/presentation/providers/study_session_provider.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/core/error/failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_recall_widget.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';
import 'study_session_screen_harness.dart';

// The session route's screen: spec D2–D8 (D8 as the owner ruled it);
// UC-STUDY-001 A3, A5, E2, E4.

String _front(WidgetTester tester) => tester
    .widgetList<Text>(find.textContaining(RegExp(r'^front ')))
    .single
    .data!;

/// Steps 3–4 of IT-CONT-004 and IT-NAV-010: the turn taken before leaving
/// stays recorded, and the deck's entry offers no Continue.
Future<void> _expectLeftForGood(LibraryEnv env, String id) async {
  final done = await env.db
      .customSelect(
        "SELECT COUNT(*) AS n FROM study_queue_items "
        "WHERE session_id = ? AND status = 'completed'",
        variables: [Variable(id)],
      )
      .getSingle();
  expect(done.read<int>('n'), greaterThanOrEqualTo(1));
  final deckId = (await sessionOf(env.db, id)).read<String>('deck_id');
  final entry = await studyEntryRepository(
    env.db,
    env.clock.now,
  ).watchEntry(deckId: deckId, now: env.clock.now()).first;
  expect(entry!.resumable, isNull);
}

void main() {
  libraryTest('the shell names the mode, the round and the stage '
      '(handoff 16; BR-STUDY-049)', (tester, env) async {
    final id = await seedSession(env, ['a', 'b', 'c']);
    await pumpSessionScreen(tester, env, id);

    final bar = tester.widget<MxStudyTopBar>(find.byType(MxStudyTopBar));
    expect(
      (bar.modeLabel, bar.current, bar.total),
      (studyEn.cardModeBrowse, 1, 3),
    );
    // The stages the session has rows in (IT-MODE-001), read, not assumed.
    final stages = (await watchSessionOnce(env.db, id)).stages.length;
    expect(
      // The deck name keeps its case (critique 2026-09-30 part 2, P4).
      find.text(
        'Lesson · ${studyEn.studyKindLearning.toUpperCase()} · STAGE 1 OF $stages',
      ),
      findsOneWidget,
    );
  });

  libraryTest('✕ asks first; Stop abandons and the same screen shows "You '
      'left early"; the turn taken stays, and the entry offers no Continue '
      '(IT-CONT-004; owner ruling 2026-09-27 on D8; UC-STUDY-001 A3)', (
    tester,
    env,
  ) async {
    final id = await seedSession(env, ['a', 'b']);
    await pumpSessionScreen(tester, env, id);
    await swipeLeft(tester);

    await tester.tap(find.byTooltip(studyEn.studySessionClose));
    await tester.pumpAndSettle();
    expect(find.text(studyEn.studyExitTitle), findsOneWidget);
    await tester.tap(find.text(studyEn.studyExitStop));
    await tester.pumpAndSettle();

    expect(find.text(studyEn.summaryLeftEarly), findsOneWidget);
    final session = await sessionOf(env.db, id);
    expect(session.read<String>('end_reason'), 'user_exit');
    await _expectLeftForGood(env, id);
  });

  libraryTest('Keep studying in the exit dialog changes nothing: the '
      'session stays open on the same card (IT-CONT-004)', (tester, env) async {
    final id = await seedSession(env, ['a', 'b']);
    await pumpSessionScreen(tester, env, id);
    final front = _front(tester);

    await tester.tap(find.byTooltip(studyEn.studySessionClose));
    await tester.pumpAndSettle();
    await tester.tap(find.text(studyEn.studyExitKeep));
    await tester.pumpAndSettle();

    expect(find.text(studyEn.studyExitTitle), findsNothing);
    expect(_front(tester), front);
    final session = await sessionOf(env.db, id);
    expect(session.read<String>('status'), 'in_progress');
  });

  libraryTest('system Back mid-session keeps the ✕ contract: it asks, Stop '
      'abandons, the turn taken stays, no Continue; Back on the summary is '
      'Done, never a return to a closed session (IT-NAV-010)', (
    tester,
    env,
  ) async {
    final id = await seedSession(env, ['a', 'b']);
    final done = <String>[];
    await pumpSessionScreen(tester, env, id, onDone: done.add);
    await swipeLeft(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(studyEn.studyExitTitle), findsOneWidget);
    await tester.tap(find.text(studyEn.studyExitStop));
    await tester.pumpAndSettle();
    expect(find.text(studyEn.summaryLeftEarly), findsOneWidget);
    await _expectLeftForGood(env, id);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final session = await sessionOf(env.db, id);
    expect(done, [session.read<String>('deck_id')]);
  });

  libraryTest('a busy database shows the error on the same card and Retry '
      'saves it (UC-STUDY-001 E2)', (tester, env) async {
    final id = await seedSession(env, ['a', 'b']);
    final sessions = env.sessions..isLocked = true;
    await pumpSessionScreen(tester, env, id);
    final front = _front(tester);

    await swipeLeft(tester);
    expect(find.text(studyEn.studyAnswerBusyTitle), findsOneWidget);
    // The answer is not saved yet: that stays danger.
    expect(
      tester.widget<MxInlineBanner>(find.byType(MxInlineBanner)).tone,
      MxBannerTone.danger,
    );
    expect(_front(tester), front);

    sessions.isLocked = false;
    await tester.tap(find.text(studyEn.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text(studyEn.studyAnswerBusyTitle), findsNothing);
    expect(_front(tester), isNot(front));
  });

  libraryTest('the deck moved to the Trash leaves once, for the Library, '
      'with a message (UC-STUDY-001 A5)', (tester, env) async {
    final id = await seedSession(env, ['a', 'b']);
    final left = <String?>[];
    await pumpSessionScreen(tester, env, id, onLeave: left.add);

    final session = await sessionOf(env.db, id);
    await env.decks.deleteDeck(deckId: session.read<String>('deck_id'));
    await tester.pumpAndSettle();

    expect(left, [null]);
    expect(find.text(studyEn.studyEntryDeckGone), findsOneWidget);
  });

  libraryTest('a write from a stale generation leaves for the deck, with no '
      'summary (UC-STUDY-001 E4)', (tester, env) async {
    final id = await seedSession(env, ['a', 'b']);
    final left = <String?>[];
    await pumpSessionScreen(tester, env, id, onLeave: left.add);

    await env.db.customUpdate(
      "UPDATE study_session SET status = 'invalidated', "
      "end_reason = 'stale_generation', ended_at = ? WHERE id = ?",
      variables: [Variable<DateTime>(env.clock.now()), Variable<String>(id)],
      updates: {env.db.studySession},
    );
    await tester.pumpAndSettle();

    final session = await sessionOf(env.db, id);
    expect(left, [session.read<String>('deck_id')]);
    expect(find.text(studyEn.studySessionStaleToast), findsOneWidget);
    expect(find.text(studyEn.summaryReset), findsNothing);
  });

  libraryTest('past Browse and Match, a learning session asks in Recall with '
      'its clock; the top bar stays (FE-A6 P4, BR-MODE-004)', (
    tester,
    env,
  ) async {
    final id = await seedSession(env, ['a', 'b']);
    await pumpSessionScreen(tester, env, id);
    await swipeLeft(tester);
    await swipeLeft(tester);

    // Browse is done, then Match; Guess sits out with two meanings
    // (BR-MODE-009). Recall's clock would run out under pumpAndSettle.
    for (final id in ['a', 'b']) {
      await tester.tap(find.text('front $id'));
      await tester.pump();
      await tester.tap(find.text('back $id'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
    }
    expect(find.byType(StudyRecallWidget), findsOneWidget);
    expect(find.text('20s / 20s'), findsOneWidget);
    expect(find.byType(MxStudyTopBar), findsOneWidget);
  });

  libraryTest('a held turn stays on screen when its answer ends the session; '
      'the summary follows its release (spec D5)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(
      env.db,
      id: 'due',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 24, 8),
      box: 2,
    );
    await lockScheduler(env.db, root.id);
    final opened = await studyEntryRepository(
      env.db,
      env.clock.now,
    ).openReviewSession(deckId: leaf.id, mode: StudyMode.recall);
    final id = (opened as Ok<String, StudyRejection>).value;
    await pumpSessionScreen(tester, env, id);
    final item = (await watchSessionOnce(env.db, id)).currentItem!;
    await env.sessions.revealRecallAnswer(
      sessionId: id,
      cardId: item.cardId,
      remainingMs: 10000,
    );
    final controller = _controllerOf(tester, id);

    await controller.answer(
      item,
      const RecallAnswer(RecallOutcome.remembered),
      shouldHoldFeedback: true,
    );
    await tester.pumpAndSettle();
    expect((await sessionOf(env.db, id)).read<String>('status'), 'completed');
    expect(find.byType(MxStudyTopBar), findsOneWidget);
    expect(find.text(studyEn.summaryReviewFinished), findsNothing);

    controller.release();
    await tester.pumpAndSettle();
    expect(find.text(studyEn.summaryReviewFinished), findsOneWidget);
  });

  libraryTest('a stalled round waits for a held turn before it settles '
      '(spec D5)', (tester, env) async {
    final id = await seedSession(env, ['a', 'b', 'c']);
    await pumpSessionScreen(tester, env, id);
    final controller = _controllerOf(tester, id);
    final first = (await watchSessionOnce(env.db, id)).currentItem!;

    await controller.answer(
      first,
      const AdvanceAnswer(),
      shouldHoldFeedback: true,
    );
    await tester.pumpAndSettle();
    final rest = {'a', 'b', 'c'}..remove(first.cardId);
    await hardDeleteCards(env.db, rest);
    await tester.pumpAndSettle();
    expect((await watchSessionOnce(env.db, id)).isStalled, isTrue);

    controller.release();
    await tester.pumpAndSettle();
    expect((await watchSessionOnce(env.db, id)).isStalled, isFalse);
  });

  libraryTest('a session that cannot be read says so and Retry reads again '
      '(UC-STUDY-001 E5)', (tester, env) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen('s'),
      overrides: [
        studySessionProvider('s').overrideWith((_) {
          reads++;
          return Stream.error(
            const UnknownDatabaseFailure(cause: '/data/memox.sqlite'),
          );
        }),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text(studyEn.studySessionErrorTitle), findsOneWidget);
    expect(find.text(studyEn.summaryAppBar), findsNothing);
    final before = reads;
    await tester.tap(find.text(studyEn.commonRetry));
    await tester.pumpAndSettle();
    expect(reads, before + 1);
  });
}

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

StudySessionController _controllerOf(WidgetTester tester, String id) =>
    ProviderScope.containerOf(tester.element(find.byType(StudySessionScreen)))
        .read(studySessionControllerProvider(id).notifier);
