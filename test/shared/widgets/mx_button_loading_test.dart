import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../support/widget_harness.dart';

// MxButton while its work runs, and what TalkBack reads of it.

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

void main() {
  // Work in progress is not a control that cannot be used: a caller that
  // also nulls onPressed while loading still gets the button at full
  // strength, its fill, its edge and its foreground as at rest (shared
  // widgets review 2026-10-07, SW-REV-003).
  testWidgets('loading is never dimmed, even with onPressed null', (
    tester,
  ) async {
    for (final tone in MxButtonTone.values) {
      await pumpMx(
        tester,
        MxButton(label: 'Save', tone: tone, onPressed: () {}),
      );
      final resting = tester.widget<Material>(_painted.first);

      await pumpMx(
        tester,
        MxButton(label: 'Save', tone: tone, isLoading: true, onPressed: null),
      );
      final loading = tester.widget<Material>(_painted.first);

      expect(find.byType(MxSpinner), findsOneWidget, reason: '$tone');
      expect(loading.color, resting.color, reason: '$tone fill');
      expect(loading.shape, resting.shape, reason: '$tone edge');
      expect(
        loading.textStyle?.color,
        resting.textStyle?.color,
        reason: '$tone',
      );
    }
  });

  testWidgets('loading keeps the width, shows a spinner and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(tester, MxButton(label: 'Save changes', onPressed: () {}));
    final restingWidth = tester.getSize(_painted.first).width;

    await pumpMx(
      tester,
      MxButton(label: 'Save changes', isLoading: true, onPressed: () => taps++),
    );
    await tester.tap(find.byType(MxButton), warnIfMissed: false);

    expect(tester.getSize(_painted.first).width, restingWidth);
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(taps, 0);
  });

  testWidgets('loading: a filled button spins onPrimary, outline primary', (
    tester,
  ) async {
    for (final (tone, isOnFill) in [
      (MxButtonTone.primary, true),
      (MxButtonTone.destructive, true),
      (MxButtonTone.secondary, false),
      (MxButtonTone.outline, false),
    ]) {
      await pumpMx(
        tester,
        MxButton(label: 'Save', tone: tone, isLoading: true, onPressed: () {}),
      );

      expect(
        tester.widget<MxSpinner>(find.byType(MxSpinner)).isOnFill,
        isOnFill,
      );
    }
  });

  testWidgets('a loading button keeps its name for TalkBack', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxButton(label: 'Save', isLoading: true, onPressed: () {}),
    );

    expect(find.bySemanticsLabel('Save'), findsOneWidget);
    handle.dispose();
  });

  // SW-REV-005: a caller that needs TalkBack to read more than the painted
  // label names it here, and the button keeps its tap and its state.
  testWidgets('semanticLabel: one node with the label, the tap and the state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxButton(
        label: '20:00',
        semanticLabel: 'Reminder time, 20:00',
        size: MxButtonSize.small,
        onPressed: () {},
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reminder time, 20:00')),
      isSemantics(
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );

    await pumpMx(
      tester,
      const MxButton(
        label: '20:00',
        semanticLabel: 'Reminder time, 20:00',
        size: MxButtonSize.small,
        onPressed: null,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reminder time, 20:00')),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });
}
