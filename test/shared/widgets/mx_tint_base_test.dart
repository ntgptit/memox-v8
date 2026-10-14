import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

import '../../support/widget_harness.dart';

// A tint is laid over the surface directly beneath it (DESIGN.md Tint Rule;
// token spec: `cardSurface` inside a card, `surface` on the page).

Color _badgeFill(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(MxBadge),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as ShapeDecoration).color!;
}

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byType(MxBadge));

void main() {
  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      testWidgets('on the page a tint is over surface', (tester) async {
        await pumpMx(
          tester,
          const MxBadge(label: '4 due'),
          brightness: brightness,
        );
        final context = _context(tester);

        expect(
          _badgeFill(tester),
          context.colors.primary.tintOver(context.colors.surface),
        );
      });

      testWidgets('inside a card a tint is over cardSurface', (tester) async {
        await pumpMx(
          tester,
          const MxCard(child: MxBadge(label: '4 due')),
          brightness: brightness,
        );
        final context = _context(tester);

        expect(MxTintBase.of(context), context.mxColors.cardSurface);
        expect(
          _badgeFill(tester),
          context.colors.primary.tintOver(context.mxColors.cardSurface),
        );
      });

      testWidgets('inside a tinted card a tint is over that tint', (
        tester,
      ) async {
        await pumpMx(
          tester,
          const MxCard(isWarning: true, child: MxBadge(label: '4 due')),
          brightness: brightness,
        );
        final context = _context(tester);
        final cardGround = context.mxColors.warning.tintOver(
          context.colors.surface,
        );

        expect(MxTintBase.of(context), cardGround);
      });

      for (final (name, overlay) in [
        ('sheet', const MxBottomSheet(child: MxBadge(label: '4 due'))),
        ('dialog', const MxDialog(content: MxBadge(label: '4 due'))),
      ]) {
        testWidgets('inside a $name a tint is over its ground', (tester) async {
          await pumpMx(tester, overlay, brightness: brightness);
          final context = _context(tester);

          expect(MxTintBase.of(context), context.colors.surfaceContainerHigh);
          expect(
            _badgeFill(tester),
            context.colors.primary.tintOver(
              context.colors.surfaceContainerHigh,
            ),
          );
        });
      }
    });
  }
}
