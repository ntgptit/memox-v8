import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_provider.dart';
import 'package:memox/features/progress/presentation/providers/watch_progress_use_case_provider.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_skeleton_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_today_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dashed_note.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_card.dart';
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
    // The segment states the range and Today the once-a-day rule; the list
    // header and the footer do not repeat them (critique 2026-09-30 part 3b).
    expect(find.text(_en.progressByDeck.toUpperCase()), findsOneWidget);
    expect(find.textContaining('LAST 7 DAYS'), findsNothing);
    expect(find.text(_en.progressFooter), findsOneWidget);
    expect(find.textContaining('counts once'), findsOneWidget);
    // Critique 2026-09-30: Today's figure is stated once, in the Today card.
    expect(find.text(_en.progressToday.toUpperCase()), findsOneWidget);
    // An eyebrow (critique 2026-09-30 part 2, P2).
    expect(
      tester.widget<Text>(find.text(_en.progressToday.toUpperCase())).style,
      tester
          .element(find.text(_en.progressToday.toUpperCase()))
          .textStyles
          .eyebrow,
    );
    // M3-D3: every section gap on the overview is AppSpacing.gutter.
    expect(
      tester.getTopLeft(find.byType(ProgressStreakWidget)).dy -
          tester.getBottomLeft(find.byType(ProgressTodayWidget)).dy,
      AppSpacing.gutter,
    );
    final total = await _row(tester, _en.progressAllDecks);
    expect(
      find.descendant(
        of: total,
        matching: find.text(_en.progressRowCardsDays(26, 6)),
      ),
      findsOneWidget,
    );
    // The total opens nothing, so it has no chevron (D3).
    expect(
      find.descendant(of: total, matching: find.byIcon(AppIcons.chevronRight)),
      findsNothing,
    );
    final topik = await _row(tester, 'Tiếng Hàn TOPIK I · Từ vựng');
    expect(
      find.descendant(
        of: topik,
        matching: find.text(_en.progressRowCardsDays(13, 6)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: topik,
        matching: find.textContaining(_en.progressRowCardDaysLead),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: topik, matching: find.byIcon(AppIcons.chevronRight)),
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
      // The card count leads the meta line (critique 2026-09-30 part 3d-1).
      find.descendant(of: basics, matching: find.textContaining('10 cards · ')),
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

  libraryTest('never studied: the places of the chart and the streak, no '
      'by-deck list of zeros, and Start studying opens the Study tab '
      '(UC-PROGRESS-001 A2, D1; critique 2026-09-30)', (tester, env) async {
    final taps = _Taps();
    await studiedDeck(env, 'IELTS Academic Word List');
    await pumpLibraryScreen(tester, env, _screen(taps));
    await _settle(tester);

    expect(find.byType(MxDashedNote), findsNWidgets(2));
    expect(
      tester
          .widget<MxButton>(
            find.widgetWithText(MxButton, _en.progressStartStudying),
          )
          .tone,
      MxButtonTone.primary,
    );
    await tester.tap(find.text(_en.progressStartStudying));
    expect(taps.study, 1);
    expect(find.text(_en.progressAllDecks), findsNothing);
    expect(find.text('IELTS Academic Word List'), findsNothing);
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
    // A local read failure is not a network fault (critique 2026-09-30).
    expect(find.byIcon(AppIcons.alert), findsOneWidget);
    expect(find.byIcon(AppIcons.offline), findsNothing);
  });

  libraryTest('a failed read says what failed, by the kind of failure '
      '(UC-PROGRESS-001 E1, BR-CORE-005)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      overrides: [
        progressProvider.overrideWith(
          (ref) => Stream<Progress>.error(
            const DatabaseLockedFailure(cause: '/data/memox.sqlite'),
          ),
        ),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.failureBusy), findsOneWidget);
    expect(find.textContaining('/data/'), findsNothing);
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
    // Shaped like the screen: Today, Streak, then the deck list (critique
    // 2026-09-30 part 3d-2, E12).
    expect(find.byType(ProgressSkeletonWidget), findsOneWidget);
    expect(find.byType(MxSkeletonList), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ProgressSkeletonWidget),
        matching: find.byType(MxCard),
      ),
      findsNWidgets(3),
    );
    handle.dispose();
  });

  libraryTest('a deck row reads its card-days in Vietnamese (D3)', (
    tester,
    env,
  ) async {
    final vi = lookupAppLocalizations(const Locale('vi'));
    await progressLibrary(env);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      locale: const Locale('vi'),
    );
    await _settle(tester);

    final topik = await _row(tester, 'Tiếng Hàn TOPIK I · Từ vựng');
    expect(
      find.descendant(
        of: topik,
        matching: find.textContaining(vi.progressRowCardDaysLead),
      ),
      findsOneWidget,
    );
  });

  libraryTest('a failed refresh keeps the figures last read and shows a '
      'warning banner with Retry; the error page is for no value yet '
      '(2.50)', (tester, env) async {
    await progressLibrary(env);
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      overrides: [
        progressProvider.overrideWith((ref) {
          reads++;
          return snapshotThenError(
            ref,
            ref.watch(watchProgressUseCaseProvider)(),
          );
        }),
      ],
    );
    await _settle(tester);

    expect(find.text('17'), findsOneWidget);
    expect(find.byType(MxErrorState), findsNothing);
    final banner = find.widgetWithText(MxInlineBanner, _en.progressStaleTitle);
    expect(banner, findsOneWidget);
    expect(tester.widget<MxInlineBanner>(banner).tone, MxBannerTone.warning);
    expect(find.text(_en.progressStaleBody), findsOneWidget);

    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(reads, 2);
    expect(find.text('17'), findsOneWidget);
    expect(banner, findsOneWidget);
  });
}
