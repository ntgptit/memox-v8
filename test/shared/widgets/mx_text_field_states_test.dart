import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/components/field_style.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'support/mx_harness.dart';

/// MxTextField across states and text scales (DESIGN.md, The One Field Rule).
void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    for (final variant in MxTextFieldVariant.values) {
      testWidgets('$name: ${variant.name} grows at 2x text and never clips', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 300,
                    child: MxTextField(
                      controller: TextEditingController(text: '042917'),
                      variant: variant,
                      label: 'Deck',
                      requiredText: 'Required',
                      message: 'Enter a name',
                      leadingIcon: Icons.search,
                      trailingAction: MxTextFieldAction(
                        icon: Icons.close,
                        semanticLabel: 'Clear',
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final Rect field = tester.getRect(find.byType(TextField));
        final Rect text = tester.getRect(find.byType(EditableText));
        expect(field.top, lessThanOrEqualTo(text.top));
        expect(field.bottom, greaterThanOrEqualTo(text.bottom));
        if (variant != MxTextFieldVariant.study) {
          expect(field.height, greaterThan(AppSize.field));
        }
      });
    }
  }

  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    double strength(BorderSide side) {
      // Contrast with the page, scaled by the edge's weight.
      final double edge = side.color.computeLuminance();
      final double page = theme.colorScheme.surface.computeLuminance();
      final double ratio = edge > page
          ? (edge + 0.05) / (page + 0.05)
          : (page + 0.05) / (edge + 0.05);
      return side.style == BorderStyle.none ? 0 : ratio * side.width;
    }

    InputDecoration decoration({
      bool hasError = false,
      bool isReadOnly = false,
    }) => mxFieldDecoration(
      colors: theme.colorScheme,
      texts: theme.textTheme,
      variant: MxTextFieldVariant.form,
      hasError: hasError,
      isReadOnly: isReadOnly,
    );

    test('$name: focused > error > resting > read-only > disabled', () {
      final double focused = strength(decoration().focusedBorder!.borderSide);
      final double error = strength(
        decoration(hasError: true).enabledBorder!.borderSide,
      );
      final double resting = strength(decoration().enabledBorder!.borderSide);
      final double readOnly = strength(
        decoration(isReadOnly: true).enabledBorder!.borderSide,
      );
      final double disabled =
          strength(decoration().disabledBorder!.borderSide) *
          AppOpacity.disabled;
      expect(focused, greaterThan(error));
      expect(error, greaterThan(resting));
      expect(resting, greaterThan(readOnly));
      expect(resting, greaterThan(disabled));
      // Read-only outranks disabled by its text: full contrast on its fill,
      // where disabled text is dimmed to `AppOpacity.disabled`.
      final ColorScheme s = theme.colorScheme;
      double contrast(Color a, Color b) {
        final double x = a.computeLuminance();
        final double y = b.computeLuminance();
        return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
      }

      final Color dimmed = Color.alphaBlend(
        s.onSurface.withValues(alpha: AppOpacity.disabled),
        s.surface,
      );
      expect(
        contrast(s.onSurface, s.surfaceContainer),
        greaterThan(contrast(dimmed, s.surface)),
      );
    });

    test('$name: every state keeps the same padding and radius', () {
      final List<InputDecoration> states = [
        decoration(),
        decoration(hasError: true),
        decoration(isReadOnly: true),
      ];
      for (final InputDecoration state in states) {
        expect(state.contentPadding, decoration().contentPadding);
        for (final InputBorder? border in [
          state.enabledBorder,
          state.focusedBorder,
          state.disabledBorder,
        ]) {
          expect(
            (border! as OutlineInputBorder).borderRadius,
            (decoration().enabledBorder! as OutlineInputBorder).borderRadius,
          );
        }
      }
    });
  }
}
