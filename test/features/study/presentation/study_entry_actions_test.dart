import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';

// Screen 14's actions and the direction sheet: UC-STUDY-001 steps 3–5, A3b;
// UC-STUDY-003; BR-STUDY-004, BR-STUDY-018, BR-STUDY-020.

final _en = lookupAppLocalizations(const Locale('en'));

StudyEntryScreen _screen(String deckId, {ValueChanged<String>? onOpen}) =>
    StudyEntryScreen(
      deckId: deckId,
      title: const Text('Deck'),
      breadcrumb: const SizedBox.shrink(),
      onOpenSession: onOpen ?? (_) {},
    );

Finder _button(String label) => find.widgetWithText(MxButton, label);

void main() {
  libraryTest('Learn on the row opens a learning session (BR-STUDY-051)', (
    tester,
    env,
  ) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2);
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(leaf, onOpen: (id) => opened = id),
    );

    await tester.tap(_button(_en.studyEntryLearn));
    await tester.pumpAndSettle();

    expect(
      (await sessionOf(env.db, opened!)).read<String>('session_kind'),
      'learning',
    );
  });

  libraryTest('with only new cards the footer is "Learn 2 new cards" with '
      'the nothing-due caption (kit onlyNew)', (tester, env) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2);
    await pumpLibraryScreen(tester, env, _screen(leaf));

    expect(_button(_en.studyEntryLearnCta(2)), findsOneWidget);
    expect(find.text(_en.studyEntryNothingDueCaption), findsOneWidget);
  });

  libraryTest('Review opens the direction sheet, Term first chosen; Start '
      'review opens the review in the direction picked (UC-STUDY-003)', (
    tester,
    env,
  ) async {
    final leaf = await sm2Leaf(env.db, env.decks, dueCards: 3);
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(leaf, onOpen: (id) => opened = id),
    );
    expect(find.text(_en.studyEntryReviewCaption(3, 3)), findsOneWidget);

    await tester.tap(_button(_en.studyEntryReviewCta(3)));
    await tester.pumpAndSettle();

    final termFirst = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, _en.studyDirectionTermFirst),
    );
    expect(termFirst.isSelected, isTrue);
    expect(find.text(_en.studyDirectionNote), findsOneWidget);

    await tester.tap(find.text(_en.studyDirectionMeaningFirst));
    await tester.pump();
    await tester.tap(_button(_en.studyDirectionStart));
    await tester.pumpAndSettle();

    expect(
      (await sessionOf(env.db, opened!)).read<String>('direction'),
      'meaning_to_korean',
    );
  });

  libraryTest('closing the sheet without Start review writes nothing '
      '(BR-STUDY-020)', (tester, env) async {
    final leaf = await sm2Leaf(env.db, env.decks, dueCards: 1);
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(leaf, onOpen: (id) => opened = id),
    );
    await tester.tap(_button(_en.studyEntryReviewCta(1)));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(180, 40));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyDirectionNote), findsNothing);
    expect(opened, isNull);
    expect(env.entries.opened, 0);
    expect(_button(_en.studyEntryReviewCta(1)), findsOneWidget);
  });

  libraryTest('a failed start says so and Try again starts it again '
      '(screen 14 startFailed)', (tester, env) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1);
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(leaf, onOpen: (id) => opened = id),
    );
    env.entries.isFailing = true;

    await tester.tap(_button(_en.studyEntryLearnCta(1)));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyEntryStartFailedTitle), findsOneWidget);
    expect(opened, isNull);

    env.entries.isFailing = false;
    await tester.tap(_button(_en.studyEntryTryAgain));
    await tester.pumpAndSettle();

    expect(opened, isNotNull);
  });

  libraryTest('a start the counts no longer allow is refused with the '
      'warning banner; the footer follows the new counts', (tester, env) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1, dueCards: 1);
    await pumpLibraryScreen(tester, env, _screen(leaf));
    await tester.tap(_button(_en.studyEntryReviewCta(1)));
    await tester.pumpAndSettle();
    // The due card is reviewed elsewhere while the sheet is open.
    await env.db.customUpdate(
      "UPDATE card_schedule SET due_at = ? WHERE card_id = 'd0'",
      variables: [Variable<DateTime>(DateTime(2026, 10, 1))],
      updates: {env.db.cardSchedule},
    );
    await tester.tap(_button(_en.studyDirectionStart));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyEntryRefusedDueTitle), findsOneWidget);
    expect(_button(_en.studyEntryLearnCta(1)), findsOneWidget);
  });

  libraryTest("today's open session shows the resume banner; Continue opens "
      'it, and the footer offers a new review instead (kit resume)', (
    tester,
    env,
  ) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2, dueCards: 1);
    final started = await env.entries.openLearningSession(deckId: leaf);
    final sessionId = (started as Ok<String, StudyRejection>).value;
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(leaf, onOpen: (id) => opened = id),
    );

    expect(
      find.text(_en.studyEntryResumeOverline.toUpperCase()),
      findsOneWidget,
    );
    expect(
      find.text(
        _en.studyEntryResumeLine(
          _en.studyKindLearning,
          _en.cardModeBrowse,
          0,
          2,
        ),
      ),
      findsOneWidget,
    );
    expect(_button(_en.studyEntryReviewInstead), findsOneWidget);

    await tester.tap(_button(_en.studyEntryContinue));
    await tester.pumpAndSettle();

    expect(opened, sessionId);
  });

  libraryTest('while a session opens every action is locked and the footer '
      'says Starting… (BR-STUDY-004, kit starting)', (tester, env) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1, dueCards: 1);
    final gate = Completer<void>();
    env.entries.gate = gate.future;
    await pumpLibraryScreen(tester, env, _screen(leaf));

    await tester.tap(_button(_en.studyEntryLearn));
    await tester.pump();

    expect(find.text(_en.studyEntryStart), findsOneWidget);
    expect(
      tester.widget<MxButton>(_button(_en.studyEntryLearn)).onPressed,
      isNull,
    );
    expect(
      tester.widget<MxButton>(find.byType(MxButton).last).isLoading,
      isTrue,
    );

    gate.complete();
    await tester.pumpAndSettle();
  });
}
