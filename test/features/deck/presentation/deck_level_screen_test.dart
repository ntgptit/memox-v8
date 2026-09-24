import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_due_strip_widget.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _vi = lookupAppLocalizations(const Locale('vi'));

Finder _rich(String text) => find.text(text, findRichText: true);

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
  libraryTest('first run: an empty Library offers to create a deck', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, deckScreen());

    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(MxEmptyState),
        matching: find.text(_en.libraryCreateDeck),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);
  });

  libraryTest('first run: only Create deck, the footnote below', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, deckScreen());

    // Features that wait are listed under Coming soon (spec A4, amended).
    expect(find.byType(MxButton), findsOneWidget);
    expect(find.text(_en.libraryEmptyFootnote), findsOneWidget);
  });

  libraryTest('the due strip leads; each deck carries its due badge', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, deckScreen());

    expect(find.text(_en.libraryDueTitle(2)), findsOneWidget);
    expect(_rich('1 overdue · 1 today · 1 new'), findsOneWidget);
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

    expect(_rich('2 overdue · 1 new'), findsOneWidget);
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

  libraryTest('a long Korean name at 2x ellipsizes without overflow (RF5)', (
    tester,
    env,
  ) async {
    await env.decks.root(List.filled(12, '한국어 어휘 공부').join(' '));
    await pumpLibraryScreen(tester, env, deckScreen(), textScale: 2);
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

  libraryTest('the root app bar holds Coming soon, which lists what waits', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, deckScreen());

    // Reorder moved to a row's sheet (ruling C-L4): one action only.
    expect(
      find.descendant(
        of: find.byType(MxAppBar),
        matching: find.byType(MxIconButton),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip(_en.libraryComingSoon));
    await tester.pumpAndSettle();

    expect(find.text(_en.libraryComingSoonBody), findsOneWidget);
    for (final feature in [
      _en.libraryStarterDecks,
      _en.libraryTags,
      _en.libraryTrash,
      _en.comingSoonStudy,
      _en.deckStudyOptions,
      _en.comingSoonProgressSort,
      _en.comingSoonTransfer,
    ]) {
      expect(find.text(feature), findsOneWidget, reason: feature);
    }
  });

  libraryTest('the search field opens the search', (tester, env) async {
    await _seed(env);
    var searches = 0;
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(onSearch: () => searches++),
    );

    await tester.tap(find.text(_en.deckSearchHint));
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

  libraryTest('the FAB waits for a first deck; the empty state offers it', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, deckScreen());
    expect(find.byType(MxFab), findsNothing);

    await env.decks.root('Korean');
    await tester.pumpAndSettle();
    expect(find.byType(MxFab), findsOneWidget);
  });

  libraryTest('the sort sheet offers only the sorts that work', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, deckScreen());
    await tester.tap(find.text(_en.deckSortManual));
    await tester.pumpAndSettle();

    // Manual, recent, name, due: the progress sort waits (spec A4, amended).
    expect(find.byType(MxOptionRow), findsNWidgets(4));
  });
}
