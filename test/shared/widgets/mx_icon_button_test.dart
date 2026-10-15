import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(IconButton),
  matching: find.byType(Material),
);

void main() {
  testWidgets('a round sizeControl box with a sizeIcon glyph', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.more,
        semanticLabel: 'More',
        onPressed: () {},
      ),
    );

    const dimens = AppDimens();
    expect(tester.getSize(_painted.first), Size.square(dimens.sizeControl));
    expect(
      tester.getSize(find.byIcon(AppIcons.more)),
      Size.square(dimens.sizeIcon),
    );
    expect(
      tester.getSize(find.byType(IconButton)).height,
      greaterThanOrEqualTo(dimens.sizeControl),
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

    expect(IconTheme.of(glyph).color, lightColorScheme.onSurface);
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
      isSemantics(tooltip: 'Close', isButton: true),
    );
    await tester.tap(find.byTooltip('Close'));

    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('disabled follows the disabled opacity', (tester) async {
    await pumpMx(
      tester,
      const MxIconButton(
        icon: AppIcons.close,
        semanticLabel: 'Close',
        onPressed: null,
      ),
    );
    final context = tester.element(find.byIcon(AppIcons.close));

    expect(
      IconTheme.of(context).color,
      context.colors.onSurface.withValues(
        alpha: context.dimens.opacityDisabledContent,
      ),
    );
  });
}
