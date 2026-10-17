import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

import '../../support/palette_status.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

const _dotKey = ValueKey('mx-status-dot');

Color? _fill(WidgetTester tester, Finder finder) =>
    switch (tester.widget<DecoratedBox>(finder).decoration) {
      final ShapeDecoration shape => shape.color,
      final BoxDecoration box => box.color,
      _ => null,
    };

void main() {
  final mx = lightStatus;
  final colors = appLightColors;

  testWidgets(
    'the status fixes the dot and fill; the label is its foreground',
    (tester) async {
      for (final (status, color, ink) in [
        (MxCardStatus.newCard, colors.mutedForeground, colors.mutedForeground),
        (MxCardStatus.learning, mx.warningFill, mx.warning),
        (MxCardStatus.reviewing, colors.primary, colors.primary),
        (MxCardStatus.mastered, mx.successFill, mx.success),
      ]) {
        await pumpMx(tester, MxStatusBadge(status: status, label: 'State'));
        final pill = find
            .descendant(
              of: find.byType(MxStatusBadge),
              matching: find.byType(DecoratedBox),
            )
            .first;

        expect(_fill(tester, pill), color.tintOver(colors.background));
        expect(_fill(tester, find.byKey(_dotKey)), color);
        expect(textColor(tester, find.text('State')), ink);
      }
    },
  );

  testWidgets('pill: 22 tall, 6 before the 6 dot, 4 gap, 8 after', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxStatusBadge(status: MxCardStatus.learning, label: 'Learning'),
    );
    final badge = tester.getRect(find.byType(MxStatusBadge));
    final dot = tester.getRect(find.byKey(_dotKey));
    final label = tester.getRect(find.text('Learning'));

    expect(badge.height, 22);
    expect(dot.size, const Size.square(6));
    expect(dot.left - badge.left, 6);
    expect(label.left - dot.right, 4);
    expect(badge.right - label.right, 8);
  });

  testWidgets('dot only: an 8 circle announced by its label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxStatusBadge(
        status: MxCardStatus.mastered,
        label: 'Mastered',
        isDot: true,
      ),
    );

    expect(tester.getSize(find.byKey(_dotKey)), const Size.square(8));
    expect(find.text('Mastered'), findsNothing);
    expect(find.bySemanticsLabel('Mastered'), findsOneWidget);
    handle.dispose();
  });
}
