import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_list_screen.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

Finder _rowTitles() => find.textContaining('한국어능력시험');

// Screen 35 (UC-TOPIK-001, BR-TOPIK-009, BR-TOPIK-022).
void main() {
  final tests = topikScreenTests();

  libraryTest('reading first, newest round first, with tags and status', (
    tester,
    env,
  ) async {
    final topik2Reading96 = tests.firstWhere(
      (t) =>
          t.level == TopikLevel.topik2 &&
          t.round == 96 &&
          t.section == TopikSection.reading,
    );
    await topikSeedCompleted(
      env,
      topik2Reading96,
      startedAt: libraryToday,
      correct: 41,
    );
    await topikSeedInProgress(
      env,
      topik2Reading96,
      startedAt: libraryToday.add(const Duration(hours: 1)),
    );
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
      overrides: topikContentOverrides(tests),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 tests'), findsOneWidget);
    expect(
      [
        for (final e in tester.widgetList<Text>(find.textContaining('#')))
          e.data,
      ],
      ['#96', '#91', '#83'],
    );
    expect(findPlainTextContaining('In progress · Best'), findsOneWidget);
    expect(find.text('Not started'), findsNWidgets(2));
    expect(findPlainTextContaining('Explanation · Words'), findsWidgets);
  });

  libraryTest('Listening shows its tests; the choice is per screen', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
      overrides: topikContentOverrides(tests),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listening'));
    await tester.pumpAndSettle();

    expect(find.text('1 test'), findsOneWidget);
    expect(findPlainTextContaining('Script'), findsWidgets);
  });

  libraryTest('the sort sheet re-orders the rows', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
      overrides: topikContentOverrides(tests),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MxChipTrigger));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest round'));
    await tester.pumpAndSettle();

    expect(
      [
        for (final e in tester.widgetList<Text>(find.textContaining('#')))
          e.data,
      ],
      ['#83', '#91', '#96'],
    );
  });

  libraryTest('a row opens its test', (tester, env) async {
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: opened.add),
      overrides: topikContentOverrides(tests),
    );
    await tester.pumpAndSettle();
    await tester.tap(_rowTitles().first);
    expect(opened, ['topik2-96-reading']);
  });

  libraryTest('a section with no test is a calm empty state with no sort '
      '(A1, The Content Gate Rule)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik1, onOpenTest: (_) {}),
      overrides: topikContentOverrides([topikTestFixture()]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.text('No tests yet for this section'), findsOneWidget);
    expect(find.byType(MxChipTrigger), findsNothing);
    expect(find.text('Listening'), findsOneWidget);
  });

  libraryTest('a submitted attempt updates the status in place (A2)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
      overrides: topikContentOverrides(tests),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not started'), findsNWidgets(3));

    await topikSeedCompleted(
      env,
      tests[5],
      startedAt: libraryToday,
      correct: 41,
    );
    await tester.pumpAndSettle();
    expect(find.text('Not started'), findsNWidgets(2));
  });
}
