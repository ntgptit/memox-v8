import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _view = CardListView(
  items: [],
  hasMore: false,
  counts: CardListCounts(all: 420, due: 40, newCards: 100, flagged: 3),
  statusCounts: CardStatusCounts(
    newCards: 100,
    beginning: 140,
    reviewing: 100,
    mastered: 80,
  ),
  workload: CardWorkload(overdue: 20, today: 20, newCards: 100),
);

Widget _host({CardListView view = _view, VoidCallback? onStudy}) => Scaffold(
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
      CardDeckSummaryWidget(view: view, algorithm: 'SM-2', onStudy: onStudy),
    ],
  ),
);

CardListView _workload(CardWorkload workload) => CardListView(
  items: const [],
  hasMore: false,
  counts: _view.counts,
  statusCounts: _view.statusCounts,
  workload: workload,
);

void main() {
  libraryTest('the summary names progress, the workload and each state', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());

    expect(
      find.text(_en.cardDeckProgress('SM-2').toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(_en.cardMasteredOf(80, 420)), findsOneWidget);
    expect(
      tester.widget<MxMasteryDonut>(find.byType(MxMasteryDonut)).fraction,
      80 / 420,
    );
    final workload = tester.widget<MxWorkloadBreakdownLine>(
      find.byType(MxWorkloadBreakdownLine),
    );
    expect(
      (workload.overdueCount, workload.todayCount, workload.newCount),
      (20, 20, 100),
    );
    for (final (label, count) in [
      (_en.cardStatusNew, 100),
      (_en.cardStatusBeginning, 140),
      (_en.cardStatusReviewing, 100),
      (_en.cardStatusMastered, 80),
    ]) {
      expect(
        find.text(_en.cardStatusCount(label, count)),
        findsOneWidget,
        reason: label,
      );
    }
  });

  libraryTest('Study this deck names the due cards and opens the entry '
      '(FE-A6 D10)', (tester, env) async {
    var studied = 0;
    await pumpLibraryScreen(tester, env, _host(onStudy: () => studied++));

    await tester.tap(find.widgetWithText(MxButton, _en.studyThisDeckDue(40)));
    expect(studied, 1);
  });

  libraryTest('with only new cards Study this deck names no count; with '
      'nothing to study, or no way in, it is absent', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        view: _workload(const CardWorkload(overdue: 0, today: 0, newCards: 3)),
        onStudy: () {},
      ),
    );
    expect(find.widgetWithText(MxButton, _en.studyThisDeck), findsOneWidget);

    await pumpLibraryScreen(
      tester,
      env,
      _host(
        view: _workload(const CardWorkload(overdue: 0, today: 0, newCards: 0)),
        onStudy: () {},
      ),
    );
    expect(find.byType(MxButton), findsNothing);

    await pumpLibraryScreen(tester, env, _host());
    expect(find.byType(MxButton), findsNothing);
  });

  libraryTest('a deck with no card yet reads 0 of 0, no division by zero', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        view: const CardListView(
          items: [],
          hasMore: false,
          counts: CardListCounts(all: 0, due: 0, newCards: 0, flagged: 0),
          statusCounts: CardStatusCounts(
            newCards: 0,
            beginning: 0,
            reviewing: 0,
            mastered: 0,
          ),
          workload: CardWorkload(overdue: 0, today: 0, newCards: 0),
        ),
      ),
    );

    expect(find.text(_en.cardMasteredOf(0, 0)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  libraryTest('the summary holds at 2x and meets the target guidelines', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host(), textScale: 2);

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });

  libraryTest('the four-state bar paints a segment per state, full height', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());

    final segments = find.descendant(
      of: find.byType(ExcludeSemantics),
      matching: find.byType(ColoredBox),
    );
    // The track and one segment per state.
    expect(segments, findsNWidgets(5));
    for (final segment in segments.evaluate()) {
      expect(segment.size!.height, greaterThan(0));
    }
  });

  libraryTest('the progress label keeps the 12 overline, one line on a phone '
      '(owner 2026-09-26, register 119)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _host());

    final label = tester.widget<Text>(
      find.text(_en.cardDeckProgress('SM-2').toUpperCase()),
    );
    expect(label.style!.fontSize, 12);
    expect(label.style!.fontWeight, FontWeight.w700);
  });
}
