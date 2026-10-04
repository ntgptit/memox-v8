import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxInlineBannerTone, (Color, Color, Color)> tones = {
      MxInlineBannerTone.warning: (
        x.warningContainer,
        x.warning,
        x.onWarningContainer,
      ),
      MxInlineBannerTone.danger: (
        s.errorContainer,
        s.error,
        s.onErrorContainer,
      ),
    };
    for (final MapEntry(key: tone, value: (ground, edge, content))
        in tones.entries) {
      testWidgets('$name: ${tone.name} reads in its container\'s on-role', (
        tester,
      ) async {
        await pumpMx(
          tester,
          SizedBox(
            width: 340,
            child: MxInlineBanner(
              tone: tone,
              title: 'Sync paused',
              message: 'Nothing was lost; changes wait on this phone.',
            ),
          ),
          theme: theme,
        );
        final BoxDecoration box =
            tester
                    .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                    .decoration
                as BoxDecoration;
        expect(box.color, ground);
        expect(box.border!.top.color, edge);
        expect(
          tester.widget<Text>(find.text('Sync paused')).style!.color,
          content,
        );
        expect(tester.widget<Icon>(find.byType(Icon).first).color, content);
      });
    }
  }

  testWidgets('its primary action comes last', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 340,
        child: MxInlineBanner(
          tone: MxInlineBannerTone.warning,
          message: 'Reminders are off in system settings.',
          actions: [
            MxInlineBannerAction(
              label: 'Open settings',
              onPressed: () {},
              isPrimary: true,
            ),
            MxInlineBannerAction(label: 'Try again', onPressed: () {}),
          ],
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Try again')).dx,
      lessThan(tester.getTopLeft(find.text('Open settings')).dx),
    );
    final List<MxButton> buttons = tester
        .widgetList<MxButton>(find.byType(MxButton))
        .toList();
    expect(buttons.last.tone, MxButtonTone.primary);
    expect(buttons.first.tone, MxButtonTone.text);
  });
}
