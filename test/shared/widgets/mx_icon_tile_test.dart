import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

import 'support/mx_harness.dart';

void main() {
  for (final size in MxIconTileSize.values) {
    testWidgets('${size.name} is a ${size.box} square with a '
        '${size.glyph} glyph', (tester) async {
      await pumpMx(tester, MxIconTile(icon: Icons.style, size: size));
      expect(tester.getSize(find.byType(MxIconTile)), Size.square(size.box));
      expect(tester.widget<Icon>(find.byIcon(Icons.style)).size, size.glyph);
    });
  }

  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxIconTileTone, (Color, Color)> pairs = {
      MxIconTileTone.tinted: (s.surfaceContainerHigh, s.onSurfaceVariant),
      MxIconTileTone.primary: (s.primaryContainer, s.onPrimaryContainer),
      MxIconTileTone.warning: (x.warning, x.onWarning),
      MxIconTileTone.success: (x.successContainer, x.onSuccessContainer),
      MxIconTileTone.caution: (x.warningContainer, x.onWarningContainer),
      MxIconTileTone.danger: (s.errorContainer, s.onErrorContainer),
    };
    for (final MapEntry(key: tone, value: (ground, glyph)) in pairs.entries) {
      testWidgets('$name: ${tone.name} glyph on its ground', (tester) async {
        await pumpMx(
          tester,
          MxIconTile(icon: Icons.style, tone: tone),
          theme: theme,
        );
        final BoxDecoration box =
            tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
                as BoxDecoration;
        expect(box.color, ground);
        expect(tester.widget<Icon>(find.byIcon(Icons.style)).color, glyph);
      });
    }
  }

  testWidgets('decorative: TalkBack skips it', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(tester, const MxIconTile(icon: Icons.style));
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
    semantics.dispose();
  });
}
