import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// A line cut with "…" clips at its box (RenderParagraph), and Be Vietnam
// Pro's stacked capitals rise above a role's own box: Ẳ would read as Ắ.
// Such a line takes its style through MxTextStyles.ellipsized (owner
// 2026-10-13, ADR-022): the role's box raised to ellipsisLineHeight.

const _stacked = 'Ẳ Ổ Ỗ Ẫ';

/// Dark pixels drawn above the paragraph's own box: the part of a glyph a
/// cut line would lose.
Future<int> _inkAboveBox(WidgetTester tester, TextStyle style) async {
  const pad = 24.0;
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Padding(
              padding: const EdgeInsets.all(pad),
              child: Text(_stacked, style: style),
            ),
          ),
        ),
      ),
    ),
  );
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await tester.runAsync(() => boundary.toImage());
  final bytes = await tester.runAsync(() => image!.toByteData());
  var ink = 0;
  for (var y = 0; y < pad; y++) {
    for (var x = 0; x < image!.width; x++) {
      final at = (y * image.width + x) * 4;
      // An opaque dark pixel: the fractional last column is translucent.
      final isOpaque = bytes!.getUint8(at + 3) == 0xFF;
      if (isOpaque && bytes.getUint8(at) < 0x80) ink++;
    }
  }
  image!.dispose();
  return ink;
}

void main() {
  final theme = buildLightTheme();
  final styles = MxTextStyles(
    theme.textTheme,
    AppColorSchemes.light,
    MxSemanticColors.light,
  );

  test('the cut-line box holds Ẳ, which tops out at 1.207 em', () {
    // (h - 1.265) / 2 + 1 >= 1.207 for the font's 1.0 / 0.265 em metrics.
    expect(
      (AppTypography.ellipsisLineHeight - 1.265) / 2 + 1,
      greaterThanOrEqualTo(1.207),
    );
  });

  test('ellipsized changes only the line height', () {
    for (final style in [
      styles.contentTitle,
      styles.rowTitle,
      styles.rowDescription,
      styles.tagLabel,
    ]) {
      final cut = styles.ellipsized(style);
      expect(cut.height, AppTypography.ellipsisLineHeight);
      expect(cut.fontSize, style.fontSize);
      expect(cut.fontWeight, style.fontWeight);
      expect(cut.letterSpacing, style.letterSpacing);
      expect(cut.color, style.color);
      expect(cut.fontFamily, style.fontFamily);
    }
  });

  testWidgets('a stacked capital rises above the role box and stays inside '
      'the cut-line box', (tester) async {
    final role = styles.rowTitle.copyWith(color: const Color(0xFF000000));

    expect(await _inkAboveBox(tester, role), greaterThan(0));
    expect(await _inkAboveBox(tester, styles.ellipsized(role)), 0);
  });
}
