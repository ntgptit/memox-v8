import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Spec UI base §4.6: the Material component themes carry the V3 defaults, so
// a raw Material widget — or one the framework builds — looks like MemoX.
void main() {
  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    final scheme = theme.colorScheme;
    final ghost = MxDerivedColors.resolve(
      scheme,
      theme.extension<MxSemanticColors>()!,
    ).ghostBorder;

    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: child)),
      ),
    );

    group(name, () {
      test('fields: filled, ghost edge, radius 12, no label gap', () {
        final fields = theme.inputDecorationTheme;
        expect(fields.filled, isTrue);
        expect(
          WidgetStateProperty.resolveAs(fields.fillColor!, <WidgetState>{}),
          scheme.surfaceContainerLow,
        );
        expect(
          WidgetStateProperty.resolveAs(fields.fillColor!, {
            WidgetState.focused,
          }),
          scheme.surfaceContainerLowest,
        );
        final edge = fields.enabledBorder! as OutlineInputBorder;
        expect(edge.borderSide.color, ghost);
        expect(edge.gapPadding, 0);
        expect(edge.borderRadius, BorderRadius.circular(12));
        expect(
          (fields.focusedBorder! as OutlineInputBorder).borderSide.color,
          scheme.primary,
        );
        expect(
          (fields.errorBorder! as OutlineInputBorder).borderSide.color,
          scheme.error,
        );
        expect(fields.hintStyle!.color, scheme.onSurfaceVariant);
        expect(fields.hintStyle!.fontSize, 14);
      });

      testWidgets('a raw TextField takes the V3 field', (tester) async {
        await pump(
          tester,
          const SizedBox(
            width: 300,
            child: TextField(decoration: InputDecoration(hintText: 'x')),
          ),
        );
        final decorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator),
        );
        final applied = decorator.decoration;
        expect(applied.filled, isTrue);
        expect(
          (applied.enabledBorder! as OutlineInputBorder).borderSide.color,
          ghost,
        );
      });
    });
  }
}
