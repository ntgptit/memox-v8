import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../support/widget_harness.dart';

RenderObject _ring(WidgetTester tester) => tester.renderObject(
  find
      .descendant(
        of: find.byType(MxSpinner),
        matching: find.byType(CustomPaint),
      )
      .first,
);

double _turns(WidgetTester tester) => tester
    .widget<RotationTransition>(
      find.descendant(
        of: find.byType(MxSpinner),
        matching: find.byType(RotationTransition),
      ),
    )
    .turns
    .value;

Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  final scheme = AppColorSchemes.light;

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

  testWidgets('a 2px ring: primary on a surface, onPrimary on a fill', (
    tester,
  ) async {
    await pumpMx(tester, const MxSpinner());
    expect(
      _ring(tester),
      paints..arc(
        color: scheme.primary,
        strokeWidth: 2,
        style: PaintingStyle.stroke,
      ),
    );

    await pumpMx(tester, const MxSpinner(isOnFill: true));
    expect(_ring(tester), paints..arc(color: scheme.onPrimary));
  });

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
}
