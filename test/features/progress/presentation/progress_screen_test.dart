import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_provider.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dashed_note.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/progress_screen_fixtures.dart';

// Screen 22 at the library level: UC-PROGRESS-001 (main, A1, A2, A3, E1,
// E2) and UC-PROGRESS-002 (main, A2, A3); FE-A9 D1, D2, D4, D8, D10, D11.

final _en = lookupAppLocalizations(const Locale('en'));

final class _Taps {
  final decks = <String>[];
  var study = 0;
}

ProgressScreen _screen(_Taps taps) => ProgressScreen(
  onOpenDeck: taps.decks.add,
  onStartStudying: () => taps.study++,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The row of [name], scrolled into view.
Future<Finder> _row(WidgetTester tester, String name) async {
  final row = find.widgetWithText(MxListRow, name);
  await tester.scrollUntilVisible(row, 200);
  return row;
}

void main() {
  libraryTest('Today, the seven bars, the streak, and a row per root deck '
      'with its four numbers under a total (UC-PROGRESS-001 step 4, D2)', (
    tester,
    env,
  ) async {
    await progressLibrary(env);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(find.text('17'), findsOneWidget);
    expect(find.text(_en.progressTodaySplit(5, 12)), findsOneWidget);
    expect(find.text(_en.progressStreakDays(4)), findsOneWidget);
    expect(find.text(_en.progressStreakIncludesToday), findsOneWidget);
    final total = await _row(tester, _en.progressAllDecks);
    expect(
      find.descendant(of: total, matching: find.text('26')),
      findsOneWidget,
    );
    final topik = await _row(tester, 'Tiếng Hàn TOPIK I · Từ vựng');
    expect(
      find.descendant(of: topik, matching: find.text('13')),
      findsOneWidget,
    );
  });

  libraryTest('the range sits above the list, after Streak (D10)', (
    tester,
    env,
  ) async {
    await progressLibrary(env);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);
    final tray = find.byWidgetPredicate((widget) => widget is MxSegmentedTray);
    await tester.scrollUntilVisible(tray, 200);

    expect(
      tester.getTopLeft(tray).dy,
      greaterThan(
        tester
            .getBottomLeft(find.text(_en.progressStreakCurrent.toUpperCase()))
            .dy,
      ),
    );
    expect(
      tester.getTopLeft(tray).dy,
      lessThan(tester.getTopLeft(find.text(_en.progressAllDecks)).dy),
    );
  });

  libraryTest('Last 30 days switches the numbers and the order at once, with '
      'no loading; the idle deck keeps full contrast (UC-PROGRESS-002 step 4, '
      'D11)', (tester, env) async {
    await progressLibrary(env);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    await tester.scrollUntilVisible(find.text(_en.progressRangeMonth), 200);
    await tester.tap(find.text(_en.progressRangeMonth));
    await tester.pump();

    expect(find.byType(MxSkeletonList), findsNothing);
    final basics = await _row(tester, 'Korean Basics');
    expect(
      find.descendant(of: basics, matching: find.text('10')),
      findsOneWidget,
    );
    final it = await _row(tester, 'IT');
    expect(
      find.descendant(of: it, matching: find.text(_en.progressNoActivity)),
      findsOneWidget,
    );
    expect(find.byWidgetPredicate((w) => w is Opacity), findsNothing);
  });

  libraryTest('a new answer updates the numbers with no skeleton (D8, '
      'UC-PROGRESS-001 A3)', (tester, env) async {
    await progressLibrary(env);
    final root = await env.decks.root('Fresh');
    await learnedCard(env.db, root.id, 'fresh');
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);
    expect(find.text('17'), findsOneWidget);

    await answer(env.db, 'fresh', libraryToday);
    await tester.pump();
    expect(find.byType(MxSkeletonList), findsNothing);
    await _settle(tester);

    expect(find.text('18'), findsOneWidget);
  });

  libraryTest('with nothing today but yesterday, the streak holds and says '
      'where it goes next (UC-PROGRESS-001 A1)', (tester, env) async {
    await progressLibrary(env, today: false);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(find.text(_en.progressTodayNone), findsOneWidget);
    expect(find.text(_en.progressStreakHeld), findsOneWidget);
    expect(find.text(_en.progressHeldNote(4)), findsOneWidget);
  });

  libraryTest('a lost streak names the day it ended', (tester, env) async {
    await progressLibrary(env, lastDaysAgo: 2);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    // Last study two days before Thursday 24 September.
    expect(find.text(_en.progressLostNote('Tuesday')), findsOneWidget);
    expect(find.text(_en.progressStreakDays(0)), findsOneWidget);
  });

  libraryTest('never studied: the places of the chart and the streak, every '
      'deck at 0, and Start studying opens the Study tab (UC-PROGRESS-001 A2, '
      'D1)', (tester, env) async {
    final taps = _Taps();
    await studiedDeck(env, 'IELTS Academic Word List');
    await pumpLibraryScreen(tester, env, _screen(taps));
    await _settle(tester);

    expect(find.byType(MxDashedNote), findsNWidgets(2));
    await tester.tap(find.text(_en.progressStartStudying));
    expect(taps.study, 1);
    final ielts = await _row(tester, 'IELTS Academic Word List');
    expect(
      find.descendant(of: ielts, matching: find.text(_en.progressNoActivity)),
      findsOneWidget,
    );
  });

  libraryTest('a quiet week says so and points to 30 days; at 30 days only '
      'the fact (UC-PROGRESS-002 A3)', (tester, env) async {
    await studiedDeck(
      env,
      'Korean Basics',
      days: [(daysAgo: 40, learning: 0, reviewing: 3)],
    );
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    await tester.scrollUntilVisible(find.text(_en.progressQuietWeek), 200);
    await tester.tap(find.text(_en.progressRangeMonth));
    await tester.pump();

    expect(find.text(_en.progressQuietWeek), findsNothing);
    expect(find.text(_en.progressQuietMonth), findsOneWidget);
  });

  libraryTest('no deck: only the empty state, no range, no total '
      '(UC-PROGRESS-002 A2)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(
      find.widgetWithText(MxEmptyState, _en.progressNoDecksTitle),
      findsOneWidget,
    );
    expect(find.text(_en.progressRangeWeek), findsNothing);
    expect(find.text(_en.progressAllDecks), findsNothing);
  });

  libraryTest('a row opens its deck; the total is not a button', (
    tester,
    env,
  ) async {
    final taps = _Taps();
    await progressLibrary(env);
    await pumpLibraryScreen(tester, env, _screen(taps));
    await _settle(tester);

    await tester.tap(await _row(tester, 'IELTS Academic Word List'));
    await tester.tap(await _row(tester, _en.progressAllDecks));

    expect(taps.decks, hasLength(1));
  });

  libraryTest('a failed read shows the error; Retry reads again '
      '(UC-PROGRESS-001 E1)', (tester, env) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      overrides: [
        progressProvider.overrideWith((ref) {
          reads++;
          return Stream<Progress>.error(StateError('read failed'));
        }),
      ],
    );
    await _settle(tester);
    expect(find.text(_en.progressErrorTitle), findsOneWidget);

    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(reads, 2);
    expect(find.text(_en.progressErrorTitle), findsOneWidget);
  });

  libraryTest('at large text in Vietnamese the streak tiles stack, so a label '
      'or a count keeps its line; at 1x they sit side by side', (
    tester,
    env,
  ) async {
    await progressLibrary(env, today: false);
    Future<(Offset, Offset)> tiles(double scale) async {
      await pumpLibraryScreen(
        tester,
        env,
        _screen(_Taps()),
        textScale: scale,
        locale: const Locale('vi'),
      );
      await _settle(tester);
      final flame = find.byIcon(AppIcons.streak);
      await tester.scrollUntilVisible(flame, 200);
      return (
        tester.getTopLeft(flame),
        tester.getTopLeft(find.byIcon(AppIcons.studiedToday)),
      );
    }

    final (current, today) = await tiles(2);
    expect(today.dy, greaterThan(current.dy));
    expect(today.dx, current.dx);

    final (current1x, today1x) = await tiles(1);
    expect(today1x.dx, greaterThan(current1x.dx));
  });

  libraryTest('loading is labelled for TalkBack', (tester, env) async {
    final never = StreamController<Progress>();
    addTearDown(never.close);
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      overrides: [progressProvider.overrideWith((ref) => never.stream)],
    );

    expect(find.bySemanticsLabel(_en.progressLoading), findsOneWidget);
    handle.dispose();
  });
}
