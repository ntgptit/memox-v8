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
// `card` inside a card, `background` on the page).

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
      testWidgets('on the page a tint is over the page', (tester) async {
        await pumpMx(
          tester,
          const MxBadge(label: '4 due'),
          brightness: brightness,
        );
        final context = _context(tester);

        expect(
          _badgeFill(tester),
          context.colors.primary.tintOver(context.colors.background),
        );
        // The token spec's precomputed primary tint over the page.
        expect(
          _badgeFill(tester),
          brightness == Brightness.light
              ? const Color(0xFFE4E2F7)
              : const Color(0xFF282731),
        );
      });

      testWidgets('inside a card a tint is over the card', (tester) async {
        await pumpMx(
          tester,
          const MxCard(child: MxBadge(label: '4 due')),
          brightness: brightness,
        );
        final context = _context(tester);

        expect(MxTintBase.of(context), context.colors.card);
        expect(
          _badgeFill(tester),
          context.colors.primary.tintOver(context.colors.card),
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
        final cardGround = context.status.warning.tintOver(
          context.colors.background,
        );

        expect(MxTintBase.of(context), cardGround);
      });

      for (final (name, overlay, ground) in [
        (
          'sheet',
          const MxBottomSheet(child: MxBadge(label: '4 due')),
          (BuildContext c) => c.colors.background,
        ),
        (
          'dialog',
          const MxDialog(content: MxBadge(label: '4 due')),
          (BuildContext c) => c.colors.card,
        ),
      ]) {
        testWidgets('inside a $name a tint is over its ground', (tester) async {
          await pumpMx(tester, overlay, brightness: brightness);
          final context = _context(tester);

          expect(MxTintBase.of(context), ground(context));
          expect(
            _badgeFill(tester),
            context.colors.primary.tintOver(ground(context)),
          );
        });
      }
    });
  }
}
