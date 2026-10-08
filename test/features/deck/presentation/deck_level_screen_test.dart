import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_due_strip_widget.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _vi = lookupAppLocalizations(const Locale('vi'));

/// A rich line as read, with the wrap glue (non-breaking spaces) read as
/// spaces.
Finder _rich(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is RichText &&
      widget.text.toPlainText().replaceAll(' ', ' ') == text,
);

/// Korean holds one overdue, one due-today and one new card; Kanji is empty.
Future<void> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  await env.decks.root('Kanji');
  final words = await env.decks.sub(korean.id, 'Words');
  await insertCard(
    env.db,
    id: 'late',
    deckId: words.id,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 22),
  );
  await insertCard(
    env.db,
    id: 'today',
    deckId: words.id,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
  );
  await insertCard(env.db, id: 'new', deckId: words.id);
}

void main() {
  libraryTest('the due strip leads; each deck carries its due badge', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, deckScreen());

    expect(find.text(_en.libraryDueTitle(2)), findsOneWidget);
    // The strip states its total's two halves; New is not due
    // (BR-STUDY-068; critique 2026-10-02).
    expect(_rich('1 overdue · 1 today'), findsOneWidget);
    expect(_rich('1 overdue · 1 today · 1 new'), findsNothing);
    expect(find.widgetWithText(MxBadge, _en.deckDueBadge(2)), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(_en.libraryDueTitle(2))).dy,
      lessThan(tester.getTopLeft(find.text('Korean')).dy),
    );
  });

  libraryTest('the FAB opens the create dialog', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, deckScreen());
    // The FAB comes in once the Library has loaded a deck.
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
  });

  libraryTest('sort by name reorders the decks', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, deckScreen());
    await tester.tap(find.text(_en.deckSortManual));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckSortName));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.commonDone));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Kanji')).dy,
      lessThan(tester.getTopLeft(find.text('Korean')).dy),
    );
    expect(find.text(_en.deckSortName), findsOneWidget);
  });

  libraryTest('the due filter hides idle decks and says so when none is left', (
    tester,
    env,
  ) async {
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, deckScreen());
    await tester.tap(find.text(_en.deckSortManual));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MxToggle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.commonDone));
    await tester.pumpAndSettle();

    expect(find.text('Kanji'), findsNothing);
    expect(
      find.text(_en.deckSortPillDueOnly(_en.deckSortManual)),
      findsOneWidget,
    );
    expect(find.text(_en.libraryNothingDueTitle), findsOneWidget);
    await tester.tap(find.text(_en.libraryShowAllDecks));
    await tester.pumpAndSettle();
    expect(find.text('Kanji'), findsOneWidget);
  });

  libraryTest('a deck made elsewhere appears without a reload (RF2)', (
    tester,
    env,
  ) async {
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, deckScreen());
    await env.decks.root('Hanja');
    await tester.pump();
    await tester.pump();

    expect(find.text('Hanja'), findsOneWidget);
  });

  libraryTest('midnight turns Due today into Overdue with no write (RF1)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, deckScreen());
    env.clock.startDay(DateTime(2026, 9, 25));
    await tester.pump();
    await tester.pump();

    // The strip leaves New out (BR-STUDY-068; critique 2026-10-02).
    expect(_rich('2 overdue'), findsOneWidget);
  });

  libraryTest('loading shows skeleton rows', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(),
      overrides: [
        deckLevelProvider(
          sort: DeckLevelSort.manual,
          filter: DeckLevelFilter.all,
        ).overrideWith((ref) => StreamController<DeckLevel>().stream),
      ],
    );

    expect(find.byType(MxSkeletonRow), findsWidgets);
  });

  libraryTest('a load error offers Retry, in plain words', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(),
      overrides: [
        deckLevelProvider(
          sort: DeckLevelSort.manual,
          filter: DeckLevelFilter.all,
        ).overrideWith(
          (ref) => Stream<DeckLevel>.error(StateError('disk I/O error')),
        ),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.libraryLoadErrorTitle), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.textContaining('disk'), findsNothing);
  });

  libraryTest('Retry after a load error loads the level again', (
    tester,
    env,
  ) async {
    var attempts = 0;
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(),
      overrides: [
        deckLevelProvider(
          sort: DeckLevelSort.manual,
          filter: DeckLevelFilter.all,
        ).overrideWith(
          (ref) => ++attempts == 1
              ? Stream<DeckLevel>.error(StateError('disk I/O error'))
              : Stream.value(
                  DeckLevel.of(
                    const [],
                    sort: DeckLevelSort.manual,
                    filter: DeckLevelFilter.all,
                  ),
                ),
        ),
      ],
    );
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byType(MxErrorState), findsNothing);
    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
  });

  libraryTest('a long Korean name meets the target guidelines (RF5)', (
    tester,
    env,
  ) async {
    await env.decks.root(List.filled(12, '한국어 어휘 공부').join(' '));
    await pumpLibraryScreen(tester, env, deckScreen());
    // The FAB scales in once a deck has loaded; measure it at rest.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });

  libraryTest('meets the target guidelines', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, deckScreen());
    await tester.pumpAndSettle();

    await expectAccessibleTargets(tester);
  });

  libraryTest('Vietnamese counts the decks in Vietnamese', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(),
      locale: const Locale('vi'),
    );

    expect(find.text(_vi.libraryDecksCount(2).toUpperCase()), findsOneWidget);
  });

  libraryTest('the root app bar holds Starter decks, Tags and Trash, as '
      'kit 01 draws it; nothing waits under Coming soon (spec D2)', (
    tester,
    env,
  ) async {
    await _seed(env);
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(
        onOpenStarterDecks: () => opened.add('starter'),
        onOpenTags: () => opened.add('tags'),
        onOpenTrash: () => opened.add('trash'),
      ),
    );

    expect(
      [
        for (final button in tester.widgetList<MxIconButton>(
          find.descendant(
            of: find.byType(MxAppBar),
            matching: find.byType(MxIconButton),
          ),
        ))
          button.semanticLabel,
      ],
      [_en.libraryStarterDecks, _en.libraryTags, _en.libraryTrash],
    );
    for (final label in [
      _en.libraryStarterDecks,
      _en.libraryTags,
      _en.libraryTrash,
    ]) {
      await tester.tap(find.byTooltip(label));
    }
    expect(opened, ['starter', 'tags', 'trash']);
  });

  libraryTest('the search field opens the search', (tester, env) async {
    await _seed(env);
    var searches = 0;
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(onSearch: () => searches++),
    );

    await tester.tap(find.text(_en.searchFieldHint));
    expect(searches, 1);
  });

  libraryTest('the due strip is gone while the library holds no card', (
    tester,
    env,
  ) async {
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, deckScreen());

    expect(find.byType(DeckDueStripWidget), findsNothing);
  });

  libraryTest('the sort sheet offers the five sorts of the kit, Progress last '
      '(BR-DECK-027)', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, deckScreen());
    await tester.tap(find.text(_en.deckSortManual));
    await tester.pumpAndSettle();

    final rows = tester.widgetList<MxOptionRow>(find.byType(MxOptionRow));
    expect(rows, hasLength(5));
    expect(
      (rows.last.title, rows.last.description),
      (_en.deckSortProgress, _en.deckSortProgressHint),
    );
  });

  libraryTest('sort by progress puts the least mastered first and the empty '
      'deck last (BR-DECK-027)', (tester, env) async {
    await _seed(env);
    final hangul = await env.decks.root('Hangul');
    final letters = await env.decks.sub(hangul.id, 'Letters');
    await insertCard(
      env.db,
      id: 'known',
      deckId: letters.id,
      learnedAt: DateTime(2026, 5, 1),
      dueAt: DateTime(2026, 10, 30),
      box: 8,
    );
    await pumpLibraryScreen(tester, env, deckScreen());
    await tester.tap(find.text(_en.deckSortManual));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckSortProgress));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.commonDone));
    await tester.pumpAndSettle();

    double top(String name) => tester.getTopLeft(find.text(name)).dy;
    expect(top('Korean'), lessThan(top('Hangul')));
    expect(top('Hangul'), lessThan(top('Kanji')));
  });

  libraryTest('the due strip is a button to Study home (critique 2026-09-30, '
      'R4)', (tester, env) async {
    final handle = tester.ensureSemantics();
    await _seed(env);
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(onOpenStudyHome: () => opened++),
    );

    await tester.tap(find.text(_en.libraryDueTitle(2)));
    expect(opened, 1);
    expect(
      tester.getSemantics(find.text(_en.libraryDueTitle(2))),
      isSemantics(isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });
}
