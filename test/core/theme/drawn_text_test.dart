import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/theme_context.dart';

import '../../support/widget_harness.dart';

// A width a layout decides on is the width `Text` draws: with the system's
// bold text on, `Text` draws bold while a painter of the bare role measured
// regular, about 1.2% short (owner 2026-10-21).

/// One line at every scale on a 360 dp phone.
const _short = 'Appearance settings';

/// Several lines at 320 dp.
const _long =
    'Appearance settings for the whole app, the theme, the text and the '
    'study screens';

/// What [drawnTextPainter] measures for [text] in the label role, laid out
/// at [width], and what `Text` draws there, under [data]'s accessibility
/// settings.
Future<({Size measured, Size drawn})> _measure(
  WidgetTester tester,
  String text, {
  required double textScale,
  MediaQueryData Function(MediaQueryData data)? data,
  double width = 360,
}) async {
  late Size measured;
  await pumpMx(
    tester,
    Builder(
      builder: (context) => MediaQuery(
        data: (data ?? (data) => data)(MediaQuery.of(context)),
        child: Builder(
          builder: (context) {
            final painter = drawnTextPainter(
              context,
              text,
              style: context.texts.label,
            )..layout(maxWidth: width);
            measured = painter.size;
            painter.dispose();
            return Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: Text(text, style: context.texts.label),
              ),
            );
          },
        ),
      ),
    ),
    textScale: textScale,
  );
  final paragraph = tester.renderObject<RenderParagraph>(find.byType(RichText));
  return (measured: measured, drawn: paragraph.size);
}

void main() {
  for (final isBold in [false, true]) {
    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets('measures what Text draws, one line and wrapped at 320 dp '
          '(bold $isBold, scale $textScale)', (tester) async {
        for (final (text, width) in [(_short, 360.0), (_long, 320.0)]) {
          final size = await _measure(
            tester,
            text,
            textScale: textScale,
            width: width,
            data: (data) => data.copyWith(boldText: isBold),
          );
          expect(size.measured.width, closeTo(size.drawn.width, 0.01));
          expect(size.measured.height, closeTo(size.drawn.height, 0.01));
        }
      });
    }
  }

  testWidgets("measures under the system's spacing overrides", (tester) async {
    final size = await _measure(
      tester,
      _long,
      textScale: 1,
      width: 320,
      data: (data) => data.applyTextStyleOverrides(
        lineHeightScaleFactorOverride: 1.6,
        letterSpacingOverride: 2,
        wordSpacingOverride: 6,
        paragraphSpacingOverride: null,
      ),
    );
    expect(size.measured.width, closeTo(size.drawn.width, 0.01));
    expect(size.measured.height, closeTo(size.drawn.height, 0.01));
  });

  // A role inherits: Text lays it over the ambient DefaultTextStyle, as a
  // ForUI button's label is laid over its content style.
  testWidgets('measures a role over the ambient default text style', (
    tester,
  ) async {
    late Size measured;
    await pumpMx(
      tester,
      DefaultTextStyle.merge(
        style: const TextStyle(letterSpacing: 3, wordSpacing: 8),
        child: Builder(
          builder: (context) {
            final painter = drawnTextPainter(
              context,
              _short,
              style: context.texts.label,
            )..layout(maxWidth: 360);
            measured = painter.size;
            painter.dispose();
            return Align(
              alignment: Alignment.topLeft,
              child: Text(_short, style: context.texts.label),
            );
          },
        ),
      ),
    );
    final drawn = tester
        .renderObject<RenderParagraph>(find.byType(RichText))
        .size;
    expect(measured.width, closeTo(drawn.width, 0.01));
  });
}
