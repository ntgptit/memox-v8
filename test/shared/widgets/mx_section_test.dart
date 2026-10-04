import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('an upper-cased overline over one card of split rows', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxSection(
          title: 'Study',
          note: 'Applies to new decks',
          children: [Text('Daily goal'), Text('New cards'), Text('Reviews')],
        ),
      ),
    );
    expect(find.text('STUDY'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('STUDY')),
      isSemantics(isHeader: true, label: 'STUDY'),
    );
    expect(find.byType(MxCard), findsOneWidget);
    expect(find.byType(MxNote), findsOneWidget);
    final double gap =
        tester.getTopLeft(find.text('New cards')).dy -
        tester.getBottomLeft(find.text('Daily goal')).dy;
    expect(gap, greaterThan(0));
    semantics.dispose();
  });
}
