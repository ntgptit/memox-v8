import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../support/widget_harness.dart';

// DEV-359: the banner lost its 1 dp hairline compensation and the reminder's
// "permission denied" body now wraps to 3 lines at 360 dp. The wrap is
// accepted only if nothing overflows at text scaling or on a small viewport.

const _heights = 800.0;

/// The viewport widths and text scales the wrap must hold at.
const _cases = [
  (width: 360.0, scale: 1.0),
  (width: 360.0, scale: 1.3),
  (width: 320.0, scale: 1.0),
  (width: 320.0, scale: 1.3),
];

/// Every line the body wraps to, measured on the laid-out paragraph.
int _lines(WidgetTester tester, String body) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.byType(MxInlineBanner), matching: find.text(body)),
  );
  expect(
    paragraph.didExceedMaxLines,
    isFalse,
    reason: 'the body is clipped by a max-lines limit',
  );
  expect(paragraph.maxLines, isNull, reason: 'the body never truncates');
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: body.length),
  );
  return boxes.map((box) => box.top.round()).toSet().length;
}

void main() {
  for (final locale in ['en', 'vi']) {
    final l10n = lookupAppLocalizations(Locale(locale));
    for (final c in _cases) {
      testWidgets(
        'the denied banner ($locale) wraps whole at ${c.width.toInt()} dp, '
        'text scale ${c.scale}',
        (tester) async {
          await pumpMx(
            tester,
            // The reminder screen's page gutter on both sides.
            SizedBox(
              width: c.width - 2 * AppSpacing.gutter,
              child: MxInlineBanner(
                tone: MxBannerTone.warning,
                title: l10n.reminderDeniedTitle,
                message: l10n.reminderDeniedBody,
                actions: [
                  MxButton(
                    label: l10n.reminderTryAgain,
                    tone: MxButtonTone.outline,
                    size: MxButtonSize.compact,
                    onPressed: () {},
                  ),
                  MxButton(
                    label: l10n.reminderOpenSystemSettings,
                    size: MxButtonSize.compact,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            textScale: c.scale,
          );
          tester.view.physicalSize = Size(c.width, _heights);
          await tester.pump();

          expect(tester.takeException(), isNull);
          final lines = _lines(tester, l10n.reminderDeniedBody);
          expect(lines, greaterThanOrEqualTo(2));

          final ground = tester.getRect(
            find
                .descendant(
                  of: find.byType(MxInlineBanner),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          final buttons = find.descendant(
            of: find.byType(MxInlineBanner),
            matching: find.byType(MxButton),
          );
          expect(buttons, findsNWidgets(2));
          final rows = <int>{};
          for (final button in tester.widgetList(buttons)) {
            final rect = tester.getRect(find.byWidget(button));
            rows.add(rect.top.round());
            expect(
              ground.contains(rect.topLeft) &&
                  ground.contains(rect.bottomRight),
              isTrue,
              reason: '$rect leaves the banner $ground',
            );
          }
          printOnFailure(
            'MEASURED banner $locale ${c.width.toInt()}dp x${c.scale}: '
            'body $lines lines, actions on ${rows.length} row(s)',
          );
          // The banner stays inside the viewport.
          expect(ground.left, greaterThanOrEqualTo(0));
          expect(ground.right, lessThanOrEqualTo(c.width));
        },
      );
    }
  }
}
