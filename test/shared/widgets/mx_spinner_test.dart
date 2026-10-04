import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import 'support/mx_harness.dart';

void main() {
  for (final size in MxSpinnerSize.values) {
    testWidgets('${size.name} is ${size.extent} square', (tester) async {
      await pumpMx(tester, MxSpinner(semanticLabel: 'Loading', size: size));
      expect(tester.getSize(find.byType(MxSpinner)), Size.square(size.extent));
    });
  }

  testWidgets('it is read by its label, and silent without one', (
    tester,
  ) async {
    await pumpMx(tester, const MxSpinner(semanticLabel: 'Loading decks'));
    expect(find.bySemanticsLabel('Loading decks'), findsOneWidget);
    await pumpMx(tester, const MxSpinner());
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
  });

  testWidgets('it turns, and stands still under reduced motion', (
    tester,
  ) async {
    await pumpMx(tester, const MxSpinner(semanticLabel: 'Loading'));
    final RotationTransition turn = tester.widget(
      find.descendant(
        of: find.byType(MxSpinner),
        matching: find.byType(RotationTransition),
      ),
    );
    final double before = turn.turns.value;
    await tester.pump(const Duration(milliseconds: 200));
    expect(turn.turns.value, isNot(before));
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MxSpinner(semanticLabel: 'Loading'),
        ),
      ),
    );
    final RotationTransition still = tester.widget(
      find.descendant(
        of: find.byType(MxSpinner),
        matching: find.byType(RotationTransition),
      ),
    );
    final double at = still.turns.value;
    await tester.pump(const Duration(milliseconds: 200));
    expect(still.turns.value, at);
  });

  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    testWidgets('$name: on its own it turns in the Indigo Accent', (
      tester,
    ) async {
      await pumpMx(tester, const MxSpinner(), theme: theme);
      expect(
        find.byType(MxSpinner),
        paints..arc(color: theme.colorScheme.onPrimaryContainer),
      );
    });
  }
}
