import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../core/theme/token_source.dart' show contrast;
import '../../support/widget_harness.dart';
import '../../support/theme_expect.dart';

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

void main() {
  final scheme = lightColorScheme;

  testWidgets('unselected: flat, outlineVariant edge, 32 tall, 8 corners', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: false, onSelected: (_) {}),
    );
    final material = tester.widget<Material>(_painted.first);
    final shape = material.shape! as MxFocusRingBorder;

    expect(tester.getSize(_painted.first).height, 32);
    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, scheme.onSurfaceVariant);
    expect(
      shape.base,
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );
    expect(find.byIcon(AppIcons.check), findsNothing);
  });

  testWidgets('selected: secondaryContainer, no edge, a leading check', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: true, onSelected: (_) {}),
    );
    final material = tester.widget<Material>(_painted.first);

    expect(material.color, scheme.secondaryContainer);
    expect(material.textStyle!.color, scheme.onSecondaryContainer);
    expect((material.shape! as OutlinedBorder).side, BorderSide.none);
    expect(tester.getSize(find.byIcon(AppIcons.check)).width, 18);
    expect(
      IconTheme.of(tester.element(find.byIcon(AppIcons.check))).color,
      scheme.onSecondaryContainer,
    );
  });

  // Material 3: 8 around the chip, 8 around the label, so 16 to a bare label;
  // a leading glyph sits 8 in and 8 before the label.
  testWidgets('the label is inset 16, or 8 + 18 + 8 after a glyph', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: false, onSelected: (_) {}),
    );
    final bare = tester.getTopLeft(_painted.first).dx;
    expect(tester.getTopLeft(find.text('Due')).dx - bare, 16);
    expect(
      tester.getTopRight(_painted.first).dx -
          tester.getTopRight(find.text('Due')).dx,
      16,
    );

    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Due',
        icon: AppIcons.filter,
        isSelected: false,
        onSelected: (_) {},
      ),
    );
    final left = tester.getTopLeft(_painted.first).dx;
    expect(tester.getTopLeft(find.byIcon(AppIcons.filter)).dx - left, 8);
    expect(tester.getTopLeft(find.text('Due')).dx - left, 8 + 18 + 8);
    expect(
      IconTheme.of(tester.element(find.byIcon(AppIcons.filter))).color,
      scheme.primary,
    );
  });

  testWidgets('selecting swaps the glyph for the check', (tester) async {
    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Due',
        icon: AppIcons.filter,
        isSelected: true,
        onSelected: (_) {},
      ),
    );

    expect(find.byIcon(AppIcons.check), findsOneWidget);
    expect(find.byIcon(AppIcons.filter), findsNothing);
  });

  testWidgets('keyboard focus draws a primary ring around the 8 corners', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: false, onSelected: (_) {}),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final shape =
        tester.widget<Material>(_painted.first).shape! as MxFocusRingBorder;

    expect(shape.ring.color, scheme.primary);
    expect(shape.ring.width, 2);
    expect(shape.gap, 2);
    expect(
      (shape.base as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(8),
    );
  });

  testWidgets('the count sits at 60% resting and at full strength selected', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Due',
        count: 12,
        isSelected: false,
        onSelected: (_) {},
      ),
    );
    expect(
      tester.widget<Text>(find.text('12')).style!.color,
      scheme.onSurfaceVariant.withValues(alpha: 0.6),
    );

    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Due',
        count: 12,
        isSelected: true,
        onSelected: (_) {},
      ),
    );
    expect(
      tester.widget<Text>(find.text('12')).style!.color,
      scheme.onSecondaryContainer,
    );
  });

  testWidgets('a tap reports the flipped selection', (tester) async {
    bool? reported;
    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Due',
        isSelected: false,
        onSelected: (v) => reported = v,
      ),
    );
    await tester.tap(find.byType(MxFilterChip));

    expect(reported, isTrue);
  });

  testWidgets('selection is announced on the button node', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: true, onSelected: (_) {}),
    );

    expect(
      tester.getSemantics(find.byType(MxFilterChip)),
      isSemantics(label: 'Due', isSelected: true, isButton: true),
    );
    handle.dispose();
  });

  testWidgets('a 32 chip with a 48 target', (tester) async {
    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Cards',
        icon: AppIcons.filter,
        isSelected: false,
        onSelected: (_) {},
      ),
    );
    await expectAccessibleTargets(tester);
  });

  // DEV-372: the button resolves its own disabled colours; a wrapper dimming
  // it again left 4.6% container and 14% content.
  testWidgets('disabled paints the theme disabled colours, dimmed once', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxFilterChip(label: 'Cards', isSelected: false, onSelected: null),
    );

    expect(
      find.ancestor(
        of: find.byType(TextButton),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    final material = tester.widget<Material>(_painted.first);
    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, scheme.onSurface.withValues(alpha: 0.38));
    expect(
      (material.shape! as OutlinedBorder).side.color,
      scheme.onSurface.withValues(alpha: 0.12),
    );

    await pumpMx(
      tester,
      const MxFilterChip(label: 'Cards', isSelected: true, onSelected: null),
    );
    expect(
      tester.widget<Material>(_painted.first).color,
      scheme.onSurface.withValues(alpha: 0.12),
    );
  });

  // SW-REV-010: a label wider than the column ends in an ellipsis.
  testWidgets('a label wider than its column ends in an ellipsis', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 200,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MxFilterChip(
            label: 'Sheet: Vocabulary_Korean_Lesson_12_Final (3 of 5)',
            count: 12,
            isSelected: false,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<Text>(
            find.text('Sheet: Vocabulary_Korean_Lesson_12_Final (3 of 5)'),
          )
          .overflow,
      TextOverflow.ellipsis,
    );
  });

  // M3F-04: the glyph read `primary`, 2.38:1 on the dark card ground.
  for (final brightness in Brightness.values) {
    testWidgets('M3F-04: the leading glyph is the accent, 3:1 on a card '
        '($brightness)', (tester) async {
      await pumpMx(
        tester,
        MxFilterChip(
          label: 'Tags',
          icon: AppIcons.filter,
          isSelected: false,
          onSelected: (_) {},
        ),
        brightness: brightness,
      );
      final context = tester.element(find.byIcon(AppIcons.filter));
      final glyph = IconTheme.of(context).color!;

      expect(glyph, accentOf(context.colors));
      expect(contrast(glyph, context.mxColors.cardSurface), greaterThan(3));
    });
  }
}
