import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_home_screen.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 34 (UC-TOPIK-001): the two exams with their test counts.
void main() {
  libraryTest('each level with its count; a tap opens it', (tester, env) async {
    final opened = <TopikLevel>[];
    await pumpLibraryScreen(
      tester,
      env,
      TopikHomeScreen(onOpenLevel: opened.add),
      overrides: topikContentOverrides(topikScreenTests()),
    );
    await tester.pumpAndSettle();

    expect(
      findPlainText('Levels 1–2 · Reading, Listening · 3 tests'),
      findsOneWidget,
    );
    expect(
      findPlainText('Levels 3–6 · Reading, Listening · 4 tests'),
      findsOneWidget,
    );
    await tester.tap(find.text('TOPIK II'));
    expect(opened, [TopikLevel.topik2]);
  });

  libraryTest('a level with no valid test says so and is not a button '
      '(BR-TOPIK-008)', (tester, env) async {
    final opened = <TopikLevel>[];
    await pumpLibraryScreen(
      tester,
      env,
      TopikHomeScreen(onOpenLevel: opened.add),
      overrides: topikContentOverrides([topikTestFixture()]),
    );
    await tester.pumpAndSettle();

    expect(
      findPlainText('Levels 1–2 · Reading, Listening · No tests yet'),
      findsOneWidget,
    );
    final row = tester.widget<MxListRow>(
      find.ancestor(of: find.text('TOPIK I'), matching: find.byType(MxListRow)),
    );
    expect(row.onTap, isNull);
    expect(row.hasChevron, isFalse);
    expect(row.isEnabled, isTrue);
    await tester.tap(find.text('TOPIK I'));
    expect(opened, isEmpty);
  });

  libraryTest('a failed read says nothing was lost; Retry reads again', (
    tester,
    env,
  ) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      TopikHomeScreen(onOpenLevel: (_) {}),
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
    expect(find.text('Nothing was lost. Try again.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(MxErrorState), findsNothing);
    expect(reads, 2);
  });

  libraryTest('loading shows the skeleton, named once', (tester, env) async {
    final pending = StreamController<List<TopikCatalogEntry>>();
    addTearDown(pending.close);
    await pumpLibraryScreen(
      tester,
      env,
      TopikHomeScreen(onOpenLevel: (_) {}),
      overrides: [topikCatalogProvider.overrideWith((ref) => pending.stream)],
    );
    expect(find.bySemanticsLabel('Loading tests'), findsOneWidget);
  });
}
