import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
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
  libraryTest('the summary names progress and the workload, and states mastery '
      'once: no four-state legend (critique 2026-09-30, R2)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());

    expect(
      find.text(_en.cardDeckProgress('SM-2').toUpperCase()),
      findsOneWidget,
    );
    // An eyebrow (critique 2026-09-30 part 2, P2).
    expect(
      tester
          .widget<Text>(find.text(_en.cardDeckProgress('SM-2').toUpperCase()))
          .style,
      tester
          .element(find.text(_en.cardDeckProgress('SM-2').toUpperCase()))
          .textStyles
          .eyebrow,
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
      expect(find.text('$label $count'), findsNothing, reason: label);
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

  libraryTest('the summary meets the target guidelines', (tester, env) async {
    await pumpLibraryScreen(tester, env, _host());

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });

  libraryTest('no four-state bar under the donut (critique 2026-09-30, R2)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());

    final segments = find.descendant(
      of: find.byType(CardDeckSummaryWidget),
      matching: find.descendant(
        of: find.byType(ExcludeSemantics),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(segments, findsNothing);
  });

  libraryTest('the progress label keeps 12, one line on a phone, now as the '
      'eyebrow (owner 2026-09-26, register 119; critique 2026-09-30 part 2)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());

    final label = tester.widget<Text>(
      find.text(_en.cardDeckProgress('SM-2').toUpperCase()),
    );
    expect(label.style!.fontSize, 12);
    expect(label.style!.fontWeight, FontWeight.w600);
  });

  // SW-REV-011: a hero statement wraps between whole terms, never "…",
  // as the Deck level hero's does (MxWorkloadBreakdownLine's contract).
  libraryTest('the workload line wraps, as a hero line does', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());

    expect(
      tester
          .widget<MxWorkloadBreakdownLine>(find.byType(MxWorkloadBreakdownLine))
          .canWrap,
      isTrue,
    );
  });
}
