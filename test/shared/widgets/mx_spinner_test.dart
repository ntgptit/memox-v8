import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

/// How far the glyph has turned, in turns, read off the rotation ForUI
/// puts around it. Null when ForUI drew it still.
double? _turns(WidgetTester tester) {
  final rotations = find.descendant(
    of: find.byType(FCircularProgress),
    matching: find.byType(Transform),
  );
  if (rotations.evaluate().isEmpty) return null;
  final matrix = tester.widget<Transform>(rotations.first).transform;
  return atan2(matrix.entry(1, 0), matrix.entry(0, 0)) / (2 * pi);
}

Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  final colors = appLightColors;

  testWidgets('four sizes off the icon scale; 16 by default', (tester) async {
    for (final (size, box) in [
      (MxSpinnerSize.inline, 16.0),
      (MxSpinnerSize.compact, 20.0),
      (MxSpinnerSize.standard, 24.0),
      (MxSpinnerSize.large, 32.0),
    ]) {
      await pumpMx(tester, MxSpinner(size: size));

      expect(tester.getSize(find.byType(MxSpinner)), Size.square(box));
    }
    await pumpMx(tester, const MxSpinner());
    expect(tester.getSize(find.byType(MxSpinner)), const Size.square(16));
  });

  testWidgets(
    'ForUI\'s progress glyph: the primary by default, the given colour when '
    'one is passed',
    (tester) async {
      await pumpMx(tester, const MxSpinner());
      final inline = spinnerIconTheme(tester, find.byType(MxSpinner));
      expect(inline.color, colors.primary);
      expect(inline.size, 16);

      // M3F-02 (owner 2026-10-15) replaced the isOnFill flag with a colour.
      await pumpMx(
        tester,
        MxSpinner(size: MxSpinnerSize.large, color: colors.errorForeground),
      );
      final large = spinnerIconTheme(tester, find.byType(MxSpinner));
      expect(large.color, colors.errorForeground);
      expect(large.size, 32);
    },
  );

  testWidgets('a quarter turn every 0.2s, also under reduced motion (O1)', (
    tester,
  ) async {
    await pumpMx(tester, const MxSpinner());
    await tester.pump(const Duration(milliseconds: 200));
    expect(_turns(tester), closeTo(0.25, 0.01));

    await pumpMx(tester, _still(const MxSpinner(key: ValueKey('still'))));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_turns(tester), closeTo(0.25, 0.01));
  });

  // Android's "Remove animations" is the platform's disableAnimations, which
  // FCircularProgress alone honours by standing still.
  testWidgets('it keeps turning under the platform\'s remove-animations (O1)', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpMx(tester, const MxSpinner());
    await tester.pump(const Duration(milliseconds: 200));

    expect(_turns(tester), closeTo(0.25, 0.01));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_turns(tester)!.abs(), closeTo(0.5, 0.01));
  });

  testWidgets('it turns once every 0.8s under reduce-motion too', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpMx(tester, const MxSpinner());
    await tester.pump(const Duration(milliseconds: 400));

    expect(_turns(tester)!.abs(), closeTo(0.5, 0.01));
  });

  testWidgets('a named spinner is heard; a bare one is not', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxSpinner(semanticLabel: 'Loading'));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);

    await pumpMx(tester, const MxSpinner());
    expect(find.bySemanticsLabel('Loading'), findsNothing);
    handle.dispose();
  });
}
