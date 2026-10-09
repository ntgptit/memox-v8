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

  testWidgets('warning: the warning container, no edge, an onWarningContainer '
      'title and message, a warning 16 glyph (FE-C1)', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(
          tone: MxBannerTone.warning,
          title: 'Title',
          message: _message,
        ),
      ),
    );
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.alert));

    expect(_ground(tester).color, semantic.warningContainer);
    expect(_ground(tester).border, isNull);
    expect(_ground(tester).borderRadius, BorderRadius.circular(12));
    expect((glyph.size, glyph.color), (16, semantic.warning));
    expect(
      tester.widget<Text>(find.text('Title')).style!.color,
      semantic.onWarningContainer,
    );
    expect(
      tester.widget<Text>(find.text(_message)).style!.color,
      semantic.onWarningContainer,
    );
  });

  testWidgets('danger: the error container, no edge, an onErrorContainer title '
      'and message, an error glyph', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(
          tone: MxBannerTone.danger,
          title: 'Title',
          message: _message,
        ),
      ),
    );

    expect(_ground(tester).color, scheme.errorContainer);
    expect(_ground(tester).border, isNull);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.alert)).color,
      scheme.error,
    );
    expect(
      tester.widget<Text>(find.text('Title')).style!.color,
      scheme.onErrorContainer,
    );
    expect(
      tester.widget<Text>(find.text(_message)).style!.color,
      scheme.onErrorContainer,
    );
  });

  testWidgets('titled: a 700 title 2 above the detail; the message reads in the on-colour '
      'either way', (tester) async {
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
      scheme.onErrorContainer,
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
      scheme.onErrorContainer,
    );
  });

  testWidgets(
    'padding 12 16, 16 below; 8 12 and 0 in a bar (no edge to inset)',
    (tester) async {
      await pumpMx(
        tester,
        _width(
          const MxInlineBanner(tone: MxBannerTone.warning, message: _message),
        ),
      );
      final banner = tester.getTopLeft(find.byType(MxInlineBanner));
      expect(tester.getTopLeft(find.byType(Icon)).dx - banner.dx, 16);
      expect(
        tester.getTopLeft(find.text(_message)) - banner,
        const Offset(40, 12),
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
      expect(tester.getTopLeft(find.text(_message)) - bar, const Offset(36, 8));
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

  testWidgets('the title and the message read in the container on-colour, in '
      'both themes (critique 2026-09-30 tone pass, T2)', (tester) async {
    for (final brightness in Brightness.values) {
      final colors = brightness == Brightness.light
          ? AppColorSchemes.light
          : AppColorSchemes.dark;
      final roles = brightness == Brightness.light
          ? MxSemanticColors.light
          : MxSemanticColors.dark;
      for (final (tone, ink) in [
        (MxBannerTone.warning, roles.onWarningContainer),
        (MxBannerTone.danger, colors.onErrorContainer),
      ]) {
        await pumpMx(
          tester,
          _width(MxInlineBanner(tone: tone, title: 'Title', message: _message)),
          brightness: brightness,
        );
        // The theme change animates.
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.text('Title')).style!.color,
          ink,
          reason: '$tone ${brightness.name}',
        );
        expect(
          tester.widget<Text>(find.text(_message)).style!.color,
          ink,
          reason: '$tone ${brightness.name} message',
        );
      }
    }
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
