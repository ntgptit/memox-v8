import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../support/widget_harness.dart';

const _message = 'The export could not be written.';

Widget _width(Widget child) => SizedBox(width: 328, child: child);

BoxDecoration _ground(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MxInlineBanner),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  final scheme = AppColorSchemes.light;
  final semantic = MxSemanticColors.light;

  testWidgets('warning: the warning soft ground, its border, an on-soft 16 '
      'glyph', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(tone: MxBannerTone.warning, message: _message),
      ),
    );
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.alert));

    expect(_ground(tester).color, semantic.warningSoft);
    expect(_ground(tester).border, Border.all(color: semantic.warningBorder));
    expect(_ground(tester).borderRadius, BorderRadius.circular(12));
    expect((glyph.size, glyph.color), (16, semantic.onWarningSoft));
  });

  testWidgets('danger: the danger soft ground, its border, an on-soft glyph', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(tone: MxBannerTone.danger, message: _message),
      ),
    );

    expect(_ground(tester).color, semantic.dangerSoft);
    expect(_ground(tester).border, Border.all(color: semantic.dangerBorder));
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.alert)).color,
      semantic.onDangerSoft,
    );
  });

  testWidgets('titled: a 700 title 2 above the detail; untitled: the lead', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(
          tone: MxBannerTone.danger,
          title: 'Export failed',
          message: _message,
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Export failed')).style!.fontWeight,
      FontWeight.w700,
    );
    expect(
      tester.widget<Text>(find.text(_message)).style!.color,
      scheme.onSurfaceVariant,
    );
    expect(
      tester.getTopLeft(find.text(_message)).dy -
          tester.getBottomLeft(find.text('Export failed')).dy,
      2,
    );

    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(tone: MxBannerTone.danger, message: _message),
      ),
    );
    expect(
      tester.widget<Text>(find.text(_message)).style!.color,
      scheme.onSurface,
    );
  });

  testWidgets(
    'padding 12 16 after the hairline, 16 below; 8 12 and 0 in a bar',
    (tester) async {
      await pumpMx(
        tester,
        _width(
          const MxInlineBanner(tone: MxBannerTone.warning, message: _message),
        ),
      );
      final banner = tester.getTopLeft(find.byType(MxInlineBanner));
      expect(tester.getTopLeft(find.byType(Icon)).dx - banner.dx, 17);
      expect(
        tester.getTopLeft(find.text(_message)) - banner,
        const Offset(41, 13),
      );
      expect(
        tester.getSize(find.byType(MxInlineBanner)).height -
            tester
                .getSize(
                  find
                      .descendant(
                        of: find.byType(MxInlineBanner),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .height,
        16,
      );

      await pumpMx(
        tester,
        _width(
          const MxInlineBanner(
            tone: MxBannerTone.warning,
            message: _message,
            isInCommitBar: true,
          ),
        ),
      );
      final bar = tester.getTopLeft(find.byType(MxInlineBanner));
      expect(tester.getTopLeft(find.text(_message)) - bar, const Offset(37, 9));
      expect(
        tester.getBottomLeft(find.byType(MxInlineBanner)).dy,
        tester
            .getBottomLeft(
              find
                  .descendant(
                    of: find.byType(MxInlineBanner),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .dy,
      );
    },
  );

  testWidgets('actions sit 8 under the message, 8 apart; a live region', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      _width(
        MxInlineBanner(
          tone: MxBannerTone.danger,
          message: _message,
          actions: [
            MxButton(
              label: 'Retry',
              size: MxButtonSize.compact,
              onPressed: () {},
            ),
            MxButton(
              label: 'Details',
              size: MxButtonSize.compact,
              tone: MxButtonTone.outline,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    final retry = find.widgetWithText(MxButton, 'Retry');
    final details = find.widgetWithText(MxButton, 'Details');

    // The compact Button paints 32 inside a 48 target, so its box starts 8
    // above the painted edge.
    expect(
      tester.getTopLeft(retry).dy -
          tester.getBottomLeft(find.text(_message)).dy,
      8,
    );
    expect(tester.getTopLeft(details).dx - tester.getTopRight(retry).dx, 8);
    expect(
      tester.getSemantics(find.text(_message)),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets('the title reads its tone\'s on-soft token; the message reads '
      'Day\'s banner style, in Night too (spec 2026-10-10 D4)', (tester) async {
    for (final (tone, foreground) in [
      (MxBannerTone.warning, semantic.onWarningSoft),
      (MxBannerTone.danger, semantic.onDangerSoft),
    ]) {
      await pumpMx(
        tester,
        _width(MxInlineBanner(tone: tone, title: 'Title', message: _message)),
      );
      expect(
        tester.widget<Text>(find.text('Title')).style!.color,
        foreground,
        reason: '$tone',
      );
      await pumpMx(
        tester,
        _width(MxInlineBanner(tone: tone, message: _message)),
      );
      expect(
        tester.widget<Text>(find.text(_message)).style!.color,
        semantic.onSoft,
        reason: '$tone untitled',
      );
    }

    const night = MxSemanticColors.dark;
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(
          tone: MxBannerTone.warning,
          title: 'Title',
          message: _message,
        ),
      ),
      brightness: Brightness.dark,
    );
    // The theme change animates.
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('Title')).style!.color,
      night.onWarningSoft,
    );
    expect(
      tester.widget<Text>(find.text(_message)).style!.color,
      AppColorSchemes.light.onSurfaceVariant,
    );
  });

  testWidgets('without a bottom margin the banner ends at its painted edge; '
      'by default it keeps 16 below (2026-10-05 L3)', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(
          tone: MxBannerTone.danger,
          message: _message,
          hasBottomMargin: false,
        ),
      ),
    );
    final flush = find.byType(MxInlineBanner);
    final painted = find
        .descendant(of: flush, matching: find.byType(DecoratedBox))
        .first;
    expect(tester.getBottomLeft(flush).dy, tester.getBottomLeft(painted).dy);

    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(tone: MxBannerTone.danger, message: _message),
      ),
    );
    final spaced = find.byType(MxInlineBanner);
    expect(
      tester.getBottomLeft(spaced).dy -
          tester
              .getBottomLeft(
                find
                    .descendant(of: spaced, matching: find.byType(DecoratedBox))
                    .first,
              )
              .dy,
      16,
    );
  });
}
