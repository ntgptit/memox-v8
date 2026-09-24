import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_note.dart';

import '../../support/widget_harness.dart';

const _rule = 'Changes apply to future sessions.';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('muted fill, ghost hairline, radius 12, padding 10 12', (
    tester,
  ) async {
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    await pumpMx(
      tester,
      const SizedBox(width: 328, child: MxNote(text: _rule)),
    );
    final box =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(MxNote),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    final note = tester.getTopLeft(find.byType(MxNote));

    expect(box.color, scheme.surfaceContainerLow);
    expect(box.border, Border.all(color: derived.ghostBorder));
    expect(box.borderRadius, BorderRadius.circular(12));
    expect(tester.getTopLeft(find.byType(Icon)).dx - note.dx, 13);
    expect(tester.getTopLeft(find.text(_rule)) - note, const Offset(37, 11));
    expect(tester.widget<Icon>(find.byType(Icon)).size, 16);
    expect(
      tester.widget<Text>(find.text(_rule)).style!.color,
      scheme.onSurfaceVariant,
    );
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('the glyph centres on the first line at ${scale}x', (
      tester,
    ) async {
      final long = List.filled(12, _rule).join(' ');
      await pumpMx(
        tester,
        SizedBox(width: 328, child: MxNote(text: long)),
        textScale: scale,
      );
      final firstLine = 12 * scale * 1.5;

      expect(
        tester.getCenter(find.byType(Icon)).dy,
        tester.getTopLeft(find.text(long)).dy + firstLine / 2,
      );
    });
  }
}
