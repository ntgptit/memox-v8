import 'package:drift/drift.dart' show Variable;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/providers/study_home_provider.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_workload_widget.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

import '../../../support/account_harness.dart';
import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';

// Screen 13, Study Home: UC-STUDY-002; BR-STUDY-008, 068, 075, 076, 077;
// FE-A8 rulings H1–H3, S1–S11.

final _en = lookupAppLocalizations(const Locale('en'));

final class _Taps {
  final sessions = <String>[];
  final decks = <String>[];
  var library = 0;
  var starterDecks = 0;
}

StudyHomeScreen _screen(_Taps taps) => StudyHomeScreen(
  onOpenSession: taps.sessions.add,
  onOpenDeck: taps.decks.add,
  onOpenLibrary: () => taps.library++,
  onOpenStarterDecks: () => taps.starterDecks++,
  onOpenSync: () {},
);

/// Screen 13 with the account feature's re-auth notice in its slot (P3b
/// B5).
StudyHomeScreen _screenWith(Widget reauthNotice) => StudyHomeScreen(
  onOpenSession: (_) {},
  onOpenDeck: (_) {},
  onOpenLibrary: () {},
  onOpenStarterDecks: () {},
  onOpenSync: () {},
  reauthNotice: reauthNotice,
);

const _account = AccountUser(
  id: 'x',
  email: 'a@example.com',
  isAnonymous: false,
  role: AccountRole.user,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// A root with its own leaf holding [fresh] new cards.
Future<String> _newRoot(LibraryEnv env, String name, int fresh) async {
  final root = await env.decks.root(name);
  final leaf = await env.decks.sub(root.id, 'Leaf');
  for (var i = 1; i <= fresh; i++) {
    await insertCard(env.db, id: '$name-$i', deckId: leaf.id, back: '$name $i');
  }
  return root.id;
}

/// A root whose one learned card rests until [dueAt].
Future<void> _restingRoot(LibraryEnv env, DateTime dueAt) async {
  final root = await env.decks.root('Resting');
  final leaf = await env.decks.sub(root.id, 'Leaf');
  await insertCard(
    env.db,
    id: 'rest',
    deckId: leaf.id,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: dueAt,
    box: 3,
  );
  await lockScheduler(env.db, root.id);
}

void main() {
  libraryTest('an expired sign-in takes the notice slot over sync (P3b B5)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screenWith(const Text('reauth')),
      overrides: [authStateOf(const ReauthRequired(_account))],
    );
    await _settle(tester);

    expect(find.text('reauth'), findsOneWidget);
  });

  libraryTest('without an expired sign-in, the slot stays empty', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _screenWith(const Text('reauth')));
    await _settle(tester);

    expect(find.text('reauth'), findsNothing);
  });

  libraryTest('loaded: the Resume card, the workload hero with its four '
      'terms, and the decks in BR-STUDY-076 order (13 loaded)', (
    tester,
    env,
  ) async {
    await openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.recall);
    await _newRoot(env, 'Spanish', 2);
    await env.decks.root('Empty');
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(
      find.text(_en.studyHomeResumeOverline.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Lesson'), findsOneWidget);
    expect(find.byType(MxLinearProgress), findsOneWidget);
    expect(find.text(_en.studyHomeResume), findsOneWidget);

    expect(find.text(_en.studyHomeDueTitle(5)), findsOneWidget);
    expect(find.textContaining(_en.studyHomeAcrossDecks(2)), findsOneWidget);
    // Critique 2026-09-30 (BR-STUDY-068): the hero states only what is due,
    // overdue and today; new and scheduled cards are in the deck rows.
    final hero = tester.widget<MxWorkloadBreakdownLine>(
      find.descendant(
        of: find.byType(StudyHomeWorkloadWidget),
        matching: find.byType(MxWorkloadBreakdownLine),
      ),
    );
    expect((hero.newCount, hero.scheduledLabel), (0, null));

    final titles = [
      for (final row in tester.widgetList<MxListRow>(find.byType(MxListRow)))
        row.title,
    ];
    expect(titles, ['Korean', 'Spanish', 'Empty']);
    // Every row that can be studied ends alike, in a chevron; its counts are
    // in its breakdown line (critique 2026-09-30).
    expect(find.byType(MxBadge), findsNothing);
    final chevrons = {
      for (final row in tester.widgetList<MxListRow>(find.byType(MxListRow)))
        row.title: row.hasChevron,
    };
    expect(chevrons, {'Korean': true, 'Spanish': true, 'Empty': false});
  });

  libraryTest('noResume: the same body with no Resume card', (
    tester,
    env,
  ) async {
    await _newRoot(env, 'Spanish', 2);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(find.text(_en.studyHomeResume), findsNothing);
    expect(find.text('Spanish'), findsOneWidget);
  });

  libraryTest('caught up: the next card falls due tomorrow, or the day is '
      'named (BR-STUDY-008, S2)', (tester, env) async {
    await _restingRoot(env, DateTime(2026, 9, 25));
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(find.text(_en.studyHomeCaughtUpTitle), findsOneWidget);
    expect(find.text(_en.studyHomeCaughtUpTomorrow), findsOneWidget);
    expect(find.text('Resting'), findsOneWidget);

    await env.db.customUpdate(
      "UPDATE card_schedule SET due_at = ? WHERE card_id = 'rest'",
      variables: [Variable<DateTime>(DateTime(2026, 9, 27))],
      updates: {env.db.cardSchedule},
    );
    await _settle(tester);
    expect(
      find.text(
        _en.studyHomeCaughtUpOn(
          DateFormat.MMMd('en').format(DateTime(2026, 9, 27)),
        ),
      ),
      findsOneWidget,
    );
  });

  libraryTest('no root deck: "Browse starter decks" first, then "Go to '
      'Library" (UC-STUDY-002 A4, 13 noDecks)', (tester, env) async {
    final taps = _Taps();
    await pumpLibraryScreen(tester, env, _screen(taps));
    await _settle(tester);

    expect(find.text(_en.studyHomeNoDecksTitle), findsOneWidget);
    expect(find.text(_en.studyHomeNoDecksBody), findsOneWidget);
    await tester.tap(find.text(_en.studyHomeBrowseStarterDecks));
    expect(taps.starterDecks, 1);
    await tester.tap(find.text(_en.studyHomeGoToLibrary));
    expect(taps.library, 1);
  });

  libraryTest('roots with no card: no number anywhere (BR-STUDY-077)', (
    tester,
    env,
  ) async {
    await env.decks.root('Empty');
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(find.text(_en.studyHomeNoCardsTitle), findsOneWidget);
    expect(find.byType(MxListRow), findsNothing);
    expect(find.textContaining(RegExp(r'\d')), findsNothing);
  });

  libraryTest('a deck row states its three counts even at zero, each with its '
      'glyph; a deck with no card says so (BR-STUDY-076, BR-STUDY-077)', (
    tester,
    env,
  ) async {
    await _newRoot(env, 'Spanish', 2);
    await env.decks.root('Empty');
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    Finder lineOf(String deck) => find.descendant(
      of: find.widgetWithText(MxListRow, deck),
      matching: find.byType(MxWorkloadBreakdownLine),
    );
    // What a reader hears: the words, not the decorative glyphs.
    String? statementOf(String deck) {
      final semantics = find.descendant(
        of: lineOf(deck),
        matching: find.byType(Semantics),
      );
      if (semantics.evaluate().isNotEmpty) {
        return tester.widget<Semantics>(semantics.first).properties.label;
      }
      return tester
          .widget<Text>(
            find.descendant(of: lineOf(deck), matching: find.byType(Text)),
          )
          .data;
    }

    expect(
      statementOf('Spanish'),
      '${_en.workloadOverdue(0)} · ${_en.workloadToday(0)} · '
      '${_en.workloadNew(2)}',
    );
    expect(statementOf('Empty'), _en.workloadNoCards);
  });

  libraryTest('a deck with no card is disabled; a deck row opens its entry; '
      'Library opens the Library (S4, H3)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final taps = _Taps();
    final spanish = await _newRoot(env, 'Spanish', 2);
    await env.decks.root('Empty');
    await pumpLibraryScreen(tester, env, _screen(taps));
    await _settle(tester);

    await tester.tap(find.text('Empty'));
    await tester.tap(find.text('Spanish'));
    await tester.tap(find.text(_en.studyHomeLibrary));
    expect(taps.decks, [spanish]);
    expect(taps.library, 1);
    // Shown, dimmed, and read as a disabled button (S4).
    expect(
      tester.getSemantics(find.text('Empty')),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  libraryTest("Resume takes today's session up and opens it (H3)", (
    tester,
    env,
  ) async {
    final taps = _Taps();
    final id = await openFiveDueReview(
      env.db,
      env.decks,
      libraryToday,
      StudyMode.recall,
    );
    await pumpLibraryScreen(tester, env, _screen(taps));
    await _settle(tester);

    await tester.tap(find.text(_en.studyHomeResume));
    await _settle(tester);

    expect(taps.sessions, [id]);
  });

  libraryTest('a refused Resume says so and opens nothing (H3, S8)', (
    tester,
    env,
  ) async {
    final taps = _Taps();
    final id = await openFiveDueReview(
      env.db,
      env.decks,
      libraryToday,
      StudyMode.recall,
    );
    await pumpLibraryScreen(tester, env, _screen(taps));
    await _settle(tester);
    // The session ends meanwhile, out of this screen's sight.
    await env.sessions.abandonSession(sessionId: id);

    await tester.tap(find.text(_en.studyHomeResume));
    await _settle(tester);

    expect(taps.sessions, isEmpty);
    expect(find.text(_en.studyHomeResumeRefused), findsOneWidget);
  });

  libraryTest('nothing overflows, each row is at '
      'least 48 tall, and no row cuts a count (BR-STUDY-076)', (
    tester,
    env,
  ) async {
    await openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.recall);
    await _newRoot(env, 'Spanish', 2);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    for (final row in find.byType(MxListRow).evaluate()) {
      expect(
        tester.getSize(find.byWidget(row.widget)).height,
        greaterThanOrEqualTo(48),
      );
    }
    final lines = find.descendant(
      of: find.byType(MxListRow),
      matching: find.descendant(
        of: find.byType(MxWorkloadBreakdownLine),
        matching: find.byType(RichText),
      ),
    );
    expect(lines, findsWidgets);
    for (final line in lines.evaluate()) {
      final paragraph = line.renderObject! as RenderParagraph;
      expect(paragraph.didExceedMaxLines, isFalse);
    }
  });

  libraryTest('a read that fails says so, and Retry reads again', (
    tester,
    env,
  ) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      overrides: [
        studyHomeProvider.overrideWith((ref) {
          reads++;
          return Stream<StudyHome>.error(StateError('read failed'));
        }),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.studyHomeErrorTitle), findsOneWidget);
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);
    expect(reads, 2);
  });

  libraryTest('loading shows the shapes, and never settles a test', (
    tester,
    env,
  ) async {
    final never = StreamController<StudyHome>();
    addTearDown(never.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      overrides: [studyHomeProvider.overrideWith((ref) => never.stream)],
    );
    await _settle(tester);

    expect(find.text(_en.studyHomeTitle), findsOneWidget);
    expect(find.byType(MxListRow), findsNothing);
  });
}
