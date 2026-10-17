import 'package:flutter/material.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
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

  libraryTest('a read that fails with a Failure speaks in its own words, and '
      'the section tray stays (UC-TOPIK-001 E1, BR-CORE-005)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
      overrides: [
        topikCatalogProvider.overrideWith(
          (ref) => Stream<List<TopikCatalogEntry>>.error(
            const DatabaseLockedFailure(cause: 'database is locked'),
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(
      find.text('Nothing was lost. The data is busy, so try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('database is locked'), findsNothing);
    expect(find.text('Listening'), findsOneWidget);
  });

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
    expect(find.byIcon(AppIcons.book), findsOneWidget);
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
    // Q-P6-3 (owner, 2026-10-16): each section has its own glyph.
    expect(find.byIcon(AppIcons.headphones), findsOneWidget);
    expect(find.byIcon(AppIcons.book), findsNothing);
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
    await tester.pump(const Duration(milliseconds: 200));
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
    // The empty state takes its section's glyph (Q-P6-3).
    expect(
      find.descendant(
        of: find.byType(MxEmptyState),
        matching: find.byIcon(AppIcons.book),
      ),
      findsOneWidget,
    );
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

  libraryTest('a failed read says nothing was lost; Retry reads again, and '
      'the section tray stays', (tester, env) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
      overrides: [
        topikCatalogProvider.overrideWith((ref) {
          reads++;
          return reads == 1
              ? Stream<List<TopikCatalogEntry>>.error(StateError('read'))
              : Stream.value(const []);
        }),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text('Listening'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(MxErrorState), findsNothing);
    expect(reads, 2);
  });
}
