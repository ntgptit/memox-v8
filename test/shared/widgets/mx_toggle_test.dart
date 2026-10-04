import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a tap flips it; it is announced as toggled', (tester) async {
    bool? next;
    await pumpMx(
      tester,
      MxToggle(
        isOn: false,
        semanticLabel: 'Due only',
        onChanged: (v) => next = v,
      ),
    );
    await tester.tap(find.byType(MxToggle));
    expect(next, isTrue);
    expect(
      tester.getSemantics(find.byType(MxToggle)),
      matchesSemantics(
        label: 'Due only',
        hasToggledState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('it paints 44x26 inside a 48 hit area', (tester) async {
    await pumpMx(tester, MxToggle(isOn: true, onChanged: (_) {}));
    expect(
      tester.getSize(find.byType(AnimatedContainer).first),
      const Size(AppSize.toggleWidth, AppSize.toggleHeight),
    );
    final Size hit = tester.getSize(find.byType(GestureDetector).first);
    expect(hit.height, greaterThanOrEqualTo(AppSize.tapTarget));
    expect(hit.width, greaterThanOrEqualTo(AppSize.tapTarget));
  });

  testWidgets('on fills primary; off rests on the highest container', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    BoxDecoration track() =>
        tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
                .decoration!
            as BoxDecoration;
    await pumpMx(tester, MxToggle(isOn: true, onChanged: (_) {}));
    expect(track().color, s.primary);
    await pumpMx(tester, MxToggle(isOn: false, onChanged: (_) {}));
    expect(track().color, s.surfaceContainerHighest);
  });

  testWidgets('disabled, a tap does nothing', (tester) async {
    await pumpMx(tester, const MxToggle(isOn: false, onChanged: null));
    await tester.tap(find.byType(MxToggle));
    expect(find.byType(Opacity), findsOneWidget);
  });
}
