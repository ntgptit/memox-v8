import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/primitives/mx_tap_target.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final Map<MxIconButtonTone, Color> inks = {
      MxIconButtonTone.standard: s.onSurfaceVariant,
      MxIconButtonTone.accent: s.onPrimaryContainer,
      MxIconButtonTone.destructive: s.error,
    };
    for (final MapEntry(key: tone, value: ink) in inks.entries) {
      testWidgets('$name: ${tone.name} draws its glyph in its role', (
        tester,
      ) async {
        await pumpMx(
          tester,
          MxIconButton(
            icon: Icons.more_vert,
            semanticLabel: 'More',
            tone: tone,
            onPressed: () {},
          ),
          theme: theme,
        );
        final IconButton button = tester.widget(find.byType(IconButton));
        expect(button.style!.foregroundColor!.resolve({}), ink);
      });
    }
    testWidgets('$name: the theme slot is the standard style', (tester) async {
      expect(
        theme.iconButtonTheme.style!.foregroundColor!.resolve({}),
        s.onSurfaceVariant,
      );
    });
  }

  testWidgets('a 20 glyph in a 36 circle with a 48 hit', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxIconButton(
        icon: Icons.close,
        semanticLabel: 'Close',
        onPressed: () => taps++,
      ),
    );
    expect(tester.getSize(find.byIcon(Icons.close)).width, AppIconSize.medium);
    final Size painted = tester.getSize(
      find.descendant(
        of: find.byType(IconButton),
        matching: find.byType(Material),
      ),
    );
    expect(painted, const Size.square(AppSize.iconButton));
    final Rect hit = tester.getRect(find.byType(MxTapTarget));
    expect(hit.size, const Size.square(AppSize.tapTarget));
    await tester.tapAt(hit.topLeft + const Offset(1, 1));
    expect(taps, 1);
  });

  testWidgets('it is read by its label and is dimmed when disabled', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxIconButton(
        icon: Icons.close,
        semanticLabel: 'Close',
        onPressed: null,
      ),
    );
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      AppOpacity.disabled,
    );
  });
}
