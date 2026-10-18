import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

import '../../support/widget_harness.dart';

void main() {
  // Per tone and theme, the glyph and the text share one colour. A warning is
  // foreground, never the amber fill, which is about 2:1 on the light page
  // (tone pass T1, critique 2026-09-30).
  final tones = [
    (
      name: 'error: glyph and text in the error colour',
      tone: MxFieldMessageTone.error,
      brightness: Brightness.light,
      ink: appLightColors.error,
    ),
    (
      name:
          'warning in dark: the glyph and the text take the warning text '
          'colour, never the amber fill (SW-REV-001)',
      tone: MxFieldMessageTone.warning,
      brightness: Brightness.dark,
      ink: MxStatusColors.dark.warning,
    ),
    (
      name:
          'warning in light: the glyph and the text take the warning text '
          'colour, never the amber fill (T1, critique 2026-09-30)',
      tone: MxFieldMessageTone.warning,
      brightness: Brightness.light,
      ink: MxStatusColors.light.warning,
    ),
  ];
  for (final c in tones) {
    testWidgets(c.name, (tester) async {
      await pumpMx(
        tester,
        MxFieldMessage(message: 'Ten tags at most', tone: c.tone),
        brightness: c.brightness,
      );

      expect(tester.widget<Icon>(find.byIcon(AppIcons.alert)).color, c.ink);
      expect(
        tester.widget<Text>(find.text('Ten tags at most')).style!.color,
        c.ink,
      );
    });
  }

  testWidgets('a long message wraps instead of truncating', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 200,
        child: MxFieldMessage(
          message: 'This deck name is already long and still keeps going on',
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));

    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(tester.getSize(find.byType(Text)).height, greaterThan(20));
  });

  testWidgets(
    'starts on the field edge with the glyph, as ForUI field messages do',
    (tester) async {
      await pumpMx(
        tester,
        const SizedBox(
          width: 300,
          child: MxFieldMessage(message: 'Name is required'),
        ),
      );

      expect(
        tester.getTopLeft(find.byIcon(AppIcons.alert)).dx -
            tester.getTopLeft(find.byType(MxFieldMessage)).dx,
        0,
      );
      final style = tester.widget<Text>(find.text('Name is required')).style!;
      expect(
        style.fontSize,
        tester.element(find.text('Name is required')).texts.caption.fontSize,
      );
    },
  );

  testWidgets('announced as a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxFieldMessage(message: 'Name is required'));

    expect(
      tester.getSemantics(find.text('Name is required')),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });
}
