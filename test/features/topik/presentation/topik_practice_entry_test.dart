import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_practice_entry_widget.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 13: "Practice" with one row, "TOPIK past papers", "{n} tests".
void main() {
  libraryTest('names the tests and opens TOPIK', (tester, env) async {
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      TopikPracticeEntryWidget(onOpen: () => opened++),
      overrides: topikContentOverrides(topikScreenTests()),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Practice'), findsOneWidget);
    expect(find.text('TOPIK past papers'), findsOneWidget);
    expect(find.text('7 tests'), findsOneWidget);
    await tester.tap(find.text('TOPIK past papers'));
    expect(opened, 1);
  });
}
