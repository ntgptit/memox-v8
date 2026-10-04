import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    testWidgets('$name: a 52 primary square read by its label', (tester) async {
      var taps = 0;
      await pumpMx(
        tester,
        MxFab(
          icon: Icons.add,
          semanticLabel: 'New deck',
          onPressed: () => taps++,
        ),
        theme: theme,
      );
      expect(
        tester.getSize(find.byType(FloatingActionButton)),
        const Size.square(AppSize.fab),
      );
      final Material fill = tester.widget(
        find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byType(Material),
        ),
      );
      expect(fill.color, theme.colorScheme.primary);
      expect(find.byTooltip('New deck'), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      expect(taps, 1);
    });

    testWidgets('$name: no shadow and no elevation, resting or focused', (
      tester,
    ) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await pumpMx(
        tester,
        MxFab(
          icon: Icons.add,
          semanticLabel: 'New deck',
          onPressed: () {},
          focusNode: focus,
        ),
        theme: theme,
      );
      void expectFlat() {
        final Iterable<Material> materials = tester.widgetList(
          find.descendant(
            of: find.byType(MxFab),
            matching: find.byType(Material),
          ),
        );
        for (final Material material in materials) {
          expect(material.elevation, 0);
        }
        final Iterable<DecoratedBox> boxes = tester.widgetList(
          find.descendant(
            of: find.byType(MxFab),
            matching: find.byType(DecoratedBox),
          ),
        );
        for (final DecoratedBox box in boxes) {
          final Decoration decoration = box.decoration;
          if (decoration is BoxDecoration) {
            expect(decoration.boxShadow, anyOf(isNull, isEmpty));
          }
        }
      }

      expectFlat();
      focus.requestFocus();
      await tester.pumpAndSettle();
      expectFlat();
      expect(
        find.byType(MxFab),
        paints..rrect(color: theme.colorScheme.onPrimaryContainer),
      );
      await tester.startGesture(
        tester.getCenter(find.byType(FloatingActionButton)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expectFlat();
    });
  }
}
