import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/shared/primitives/focus_ring.dart';
import 'package:memox/shared/primitives/pressable_surface.dart';

import '../../support/design_system_harness.dart';

final _shape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(AppRadius.md),
);

PressableSurface _surface({VoidCallback? onTap, Widget? child}) =>
    PressableSurface(
      shape: _shape,
      inkColor: const Color(0xFF000000),
      onTap: onTap,
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.gutter),
      semanticLabel: 'Open',
      child: child ?? const Text('Open the deck'),
    );

void main() {
  testWidgets('a tap runs the action, and the press inks at 12 %', (
    tester,
  ) async {
    var taps = 0;
    await pumpDesignSystem(tester, _surface(onTap: () => taps++));

    await tester.tap(find.text('Open the deck'));
    expect(taps, 1);
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(
      ink.overlayColor!.resolve({WidgetState.pressed}),
      const Color(0xFF000000).withValues(alpha: AppOpacity.pressed),
    );
  });

  testWidgets('without an action it is disabled: dimmed and announced so', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpDesignSystem(tester, _surface());

    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      AppOpacity.disabled,
    );
    expect(
      tester.getSemantics(find.byType(PressableSurface)),
      matchesSemantics(
        label: 'Open',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('keyboard focus draws the ring, and only then', (tester) async {
    await pumpDesignSystem(tester, _surface(onTap: () {}));
    expect(tester.widget<FocusRing>(find.byType(FocusRing)).isVisible, isFalse);

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(tester.widget<FocusRing>(find.byType(FocusRing)).isVisible, isTrue);
  });

  testWidgets('start padding is on the right in a right-to-left layout', (
    tester,
  ) async {
    await pumpDesignSystem(
      tester,
      _surface(onTap: () {}),
      direction: TextDirection.rtl,
    );

    final surface = tester.getRect(find.byType(InkWell));
    final text = tester.getRect(find.text('Open the deck'));
    expect(surface.right - text.right, AppSpacing.gutter);
  });

  for (final scale in designSystemTextScales) {
    testWidgets('at text scale $scale it grows and keeps a 48 dp target', (
      tester,
    ) async {
      await pumpDesignSystem(
        tester,
        SizedBox(width: 320, child: _surface(onTap: () {})),
        width: 320,
        textScale: scale,
      );

      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(PressableSurface));
      expect(size.height, greaterThanOrEqualTo(AppSize.touchTarget));
    });
  }
}
