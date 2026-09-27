import 'package:memox/shared/widgets/mx_button.dart';

import '../support/study_entry_fixtures.dart';

import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
// Study routes (FE-A6 D1, D2, D10): the entry from a deck, Back, and the
// full-screen session route. Split from library_routes_test.dart.

import '../support/study_fixtures.dart';

import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_resume_widget.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) =>
    _tap(tester, find.byTooltip(_en.commonBack));

/// Korean › Words › Verbs, with Grammar beside Words.
Future<void> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await env.decks.sub(korean.id, 'Grammar');
  await env.decks.sub(words.id, 'Verbs');
}

void main() {
  libraryTest('Study from a deck opens its entry; Back returns to that deck '
      'and no session is made (IT-NAV-008, FE-A6 D1, D10)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.byTooltip(_en.deckActions));
    // The sheet's row, not the bottom nav's Study tab.
    await _tap(
      tester,
      find.descendant(
        of: find.byType(MxActionSheetCommandRow),
        matching: find.text(_en.studyThisDeck),
      ),
    );

    expect(find.byType(StudyEntryScreen), findsOneWidget);
    expect(_barTitle('Korean'), findsOneWidget);
    await _back(tester);
    expect(find.byType(StudyEntryScreen), findsNothing);
    expect(_barTitle('Korean'), findsOneWidget);
    final sessions = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM study_session')
        .getSingle();
    expect(sessions.read<int>('n'), 0);
  });

  libraryTest('Back from the Study Entry and its review pick makes no '
      'session and returns to the source deck; the next visit has no '
      'Continue (IT-NAV-009, BR-STUDY-020, FE-A6 P3 E1)', (tester, env) async {
    await insertFiveDue(env.db, env.decks);
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.text('Lesson'));

    Future<void> openEntry() async {
      await _tap(tester, find.byTooltip(_en.deckActions));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(MxActionSheetCommandRow),
          matching: find.text(_en.studyThisDeck),
        ),
      );
    }

    await openEntry();
    expect(find.byType(StudyEntryScreen), findsOneWidget);
    final modes = tester.widgetList<MxOptionRow>(find.byType(MxOptionRow));
    expect(modes.first.title, _en.cardModeMatch);
    expect(modes.first.isSelected, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(StudyEntryScreen), findsNothing);
    expect(_barTitle('Lesson'), findsOneWidget);
    final sessions = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM study_session')
        .getSingle();
    expect(sessions.read<int>('n'), 0);

    await openEntry();
    expect(find.byType(StudyEntryResumeWidget), findsNothing);
  });

  libraryTest('a session is a full-screen route with no tab bar; ✕ shows '
      'its summary and Done returns to its deck (FE-A6 D2)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final lesson = await env.decks.sub(korean.id, 'Lesson');
    await insertCard(env.db, id: 'n1', deckId: lesson.id);
    final opened = await studyEntryRepository(
      env.db,
      env.clock.now,
    ).openLearningSession(deckId: lesson.id);
    final id = (opened as Ok<String, StudyRejection>).value;
    await pumpMemoxApp(tester, env);

    unawaited(
      GoRouter.of(tester.element(find.byType(MxBottomNav)))
          .push(AppRoutes.studySession(id)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StudySessionScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);

    await _tap(tester, find.byTooltip(_en.studySessionClose));
    await _tap(tester, find.text(_en.summaryDone));

    expect(find.byType(StudySessionScreen), findsNothing);
    expect(_barTitle('Lesson'), findsOneWidget);
  });

  Finder navTab(String label) =>
      find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

  libraryTest('the Study tab lists the root decks; a row opens that deck\'s '
      'Study Entry and makes no session (FE-A8 H3)', (tester, env) async {
    await insertFiveDue(env.db, env.decks);
    await pumpMemoxApp(tester, env);
    await _tap(tester, navTab(_en.navStudy));

    expect(find.byType(StudyHomeScreen), findsOneWidget);
    await _tap(tester, find.text('Korean'));

    expect(find.byType(StudyEntryScreen), findsOneWidget);
    final sessions = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM study_session')
        .getSingle();
    expect(sessions.read<int>('n'), 0);
  });

  libraryTest("Resume on the Study tab opens today's session; Library opens "
      'the Library (FE-A8 H3)', (tester, env) async {
    await openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.recall);
    await pumpMemoxApp(tester, env);
    await _tap(tester, navTab(_en.navStudy));

    await tester.tap(find.text(_en.studyHomeResume));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(StudySessionScreen), findsOneWidget);

    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _tap(tester, find.text(_en.summaryDone));
    await _tap(tester, navTab(_en.navStudy));
    await _tap(tester, find.widgetWithText(MxButton, _en.studyHomeLibrary));
    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });
}
