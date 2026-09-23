import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(IconButton),
  matching: find.byType(Material),
);

void main() {
  testWidgets('a 36 ink circle, a 20 glyph and a 48 target', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.more,
        semanticLabel: 'More',
        onPressed: () {},
      ),
    );

    expect(tester.getSize(_painted.first), const Size.square(36));
    expect(tester.getSize(find.byIcon(AppIcons.more)), const Size.square(20));
    expect(
      tester.getSize(find.byType(IconButton)).height,
      greaterThanOrEqualTo(48),
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('the glyph is onSurface on no fill', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.search,
        semanticLabel: 'Search',
        onPressed: () {},
      ),
    );
    final glyph = tester.element(find.byIcon(AppIcons.search));

    expect(IconTheme.of(glyph).color, AppColorSchemes.light.onSurface);
    expect(tester.widget<Material>(_painted.first).color?.a ?? 0, 0);
  });

  testWidgets('the semantic label names the control and a tap fires', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.close,
        semanticLabel: 'Close',
        onPressed: () => taps++,
      ),
    );
    // IconButton exposes the name as its semantics tooltip, which TalkBack
    // reads as the control's name.
    expect(
      tester.getSemantics(find.byType(IconButton)),
      containsSemantics(tooltip: 'Close', isButton: true),
    );
    await tester.tap(find.byTooltip('Close'));

    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('disabled dims to 0.38', (tester) async {
    await pumpMx(
      tester,
      const MxIconButton(
        icon: AppIcons.close,
        semanticLabel: 'Close',
        onPressed: null,
      ),
    );

    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byType(IconButton),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
  });
}
