import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
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
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());

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

  libraryTest('the level line leads; each deck carries its own workload', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());

    // The level line and the Korean row say the same.
    expect(_rich('1 overdue · 1 today · 1 new'), findsNWidgets(2));
    expect(_rich(_en.workloadNoCards), findsOneWidget);
    expect(
      tester.getTopLeft(_rich('1 overdue · 1 today · 1 new').first).dy,
      lessThan(tester.getTopLeft(find.text('Korean')).dy),
    );
  });

  libraryTest('the FAB opens the create dialog', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());
    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
  });

  libraryTest('sort by name reorders the decks', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());
    await tester.tap(find.text(_en.deckSortTrigger(_en.deckSortManual)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckSortName));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Kanji')).dy,
      lessThan(tester.getTopLeft(find.text('Korean')).dy),
    );
    expect(find.text(_en.deckSortTrigger(_en.deckSortName)), findsOneWidget);
  });

  libraryTest('the due filter hides idle decks and says so when none is left', (
    tester,
    env,
  ) async {
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());
    await tester.tap(find.text(_en.deckFilterTrigger(_en.deckFilterAll)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckFilterDue));
    await tester.pumpAndSettle();

    expect(find.text('Kanji'), findsNothing);
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
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());
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
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());
    env.clock.startDay(DateTime(2026, 9, 25));
    await tester.pump();
    await tester.pump();

    expect(_rich('2 overdue · 1 new'), findsNWidgets(2));
  });

  libraryTest('loading shows skeleton rows', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const DeckLevelScreen(),
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
      const DeckLevelScreen(),
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

  libraryTest('a long Korean name at 2x ellipsizes without overflow (RF5)', (
    tester,
    env,
  ) async {
    await env.decks.root(List.filled(12, '한국어 어휘 공부').join(' '));
    await pumpLibraryScreen(tester, env, const DeckLevelScreen(), textScale: 2);

    expect(tester.takeException(), isNull);
  });

  libraryTest('meets the target guidelines', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());

    await expectAccessibleTargets(tester);
  });

  libraryTest('Vietnamese names the header in Vietnamese', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      const DeckLevelScreen(),
      locale: const Locale('vi'),
    );

    expect(find.text(_vi.libraryDecksHeader.toUpperCase()), findsOneWidget);
  });
}
