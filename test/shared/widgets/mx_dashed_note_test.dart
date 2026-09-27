import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_dashed_note.dart';

import '../../support/widget_harness.dart';

// FE-A9 D6: kit 22's per-chart empty.

const _line = 'A streak starts with your first study day.';

void main() {
  testWidgets('a centred note line on the muted fill, padded 24 16', (
    tester,
  ) async {
    final scheme = AppColorSchemes.light;
    await pumpMx(
      tester,
      const SizedBox(width: 328, child: MxDashedNote(text: _line)),
    );
    final text = tester.widget<Text>(find.text(_line));
    final box =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(MxDashedNote),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(text.textAlign, TextAlign.center);
    expect(text.style!.color, scheme.onSurfaceVariant);
    expect(box.color, scheme.surfaceContainerLow);
    expect(
      tester.getTopLeft(find.text(_line)).dy -
          tester.getTopLeft(find.byType(MxDashedNote)).dy,
      24,
    );
  });

  testWidgets('TalkBack reads the line once', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxDashedNote(text: _line));

    expect(find.bySemanticsLabel(_line), findsOneWidget);
    handle.dispose();
  });
}
