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

      testWidgets('raw buttons take the V3 shape, height and tones', (
        tester,
      ) async {
        await pump(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Filled')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              TextButton(onPressed: () {}, child: const Text('Text')),
            ],
          ),
        );
        for (final label in ['Filled', 'Outlined', 'Text']) {
          final box = find.ancestor(
            of: find.text(label),
            matching: find.byType(Material),
          );
          final material = tester.widget<Material>(box.first);
          expect(tester.getSize(box.first).height, 48, reason: label);
          expect(
            (material.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(12),
            reason: label,
          );
        }
        Material paintOf(String label) => tester.widget<Material>(
          find
              .ancestor(of: find.text(label), matching: find.byType(Material))
              .first,
        );
        expect(paintOf('Filled').color, scheme.primary);
        expect(paintOf('Text').color, anyOf(isNull, Colors.transparent));
        expect(
          (paintOf('Outlined').shape! as RoundedRectangleBorder).side.color,
          scheme.outlineVariant,
        );
      });

      testWidgets('a raw IconButton is the 36 round V3 icon button', (
        tester,
      ) async {
        await pump(
          tester,
          IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
        );
        final ink = find.descendant(
          of: find.byType(IconButton),
          matching: find.byType(Material),
        );
        expect(tester.getSize(ink.first), const Size.square(36));
        expect(tester.widget<Material>(ink.first).shape, isA<CircleBorder>());
        expect(tester.getSize(find.byType(IconButton)), const Size.square(48));
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
