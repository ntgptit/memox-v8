import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a trigger opens what it names and shows a chevron', (
    tester,
  ) async {
    var opened = 0;
    await pumpMx(
      tester,
      MxChipTrigger(label: 'Manual', onOpen: () => opened++),
    );
    await tester.tap(find.text('Manual'));
    expect(opened, 1);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });

  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    testWidgets('$name: in force, it says so beyond its tint', (tester) async {
      final ColorScheme s = theme.colorScheme;
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpMx(
        tester,
        MxChipTrigger(
          label: 'Manual · Due only',
          onOpen: () {},
          isActive: true,
        ),
        theme: theme,
      );
      final BoxDecoration ground =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(MxChipTrigger),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(ground.color, s.primaryContainer);
      expect(ground.border!.top.color, s.onPrimaryContainer);
      expect(
        tester.getSemantics(find.byType(MxChipTrigger)),
        isSemantics(isButton: true, isSelected: true, hasSelectedState: true),
      );
      semantics.dispose();
    });
  }
}
