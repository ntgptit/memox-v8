import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('unselected: lowest fill, outline edge, onSurface label', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: false, onSelected: (_) {}),
    );
    final material = tester.widget<Material>(_painted.first);

    expect(tester.getSize(_painted.first).height, 28);
    expect(material.color, scheme.surfaceContainerLowest);
    expect(material.textStyle!.color, scheme.onSurface);
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide(color: scheme.outline),
    );
  });

  testWidgets('selected: primary fill, onPrimary label, no edge', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: true, onSelected: (_) {}),
    );
    final material = tester.widget<Material>(_painted.first);

    expect(material.color, scheme.primary);
    expect(material.textStyle!.color, scheme.onPrimary);
    expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
  });

  testWidgets('the count rests in onSurfaceVariant and is full ink selected', (
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
      scheme.onSurfaceVariant,
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
    expect(tester.widget<Text>(find.text('12')).style!.color, scheme.onPrimary);
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

  testWidgets('a 28 pill with a 48 target; disabled at 0.38', (tester) async {
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

    await pumpMx(
      tester,
      const MxFilterChip(label: 'Cards', isSelected: false, onSelected: null),
    );
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byType(TextButton),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
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

  testWidgets('the chip edge is outline; focus draws the shared MxFocusRing '
      'in primaryForeground', (tester) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: false, onSelected: (_) {}),
    );
    final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
    expect(style.side!.resolve({})!.color, scheme.outline);
    // The ring is the shared one, not the Material side.
    expect(style.side!.resolve({WidgetState.focused})!.color, scheme.outline);
    expect(
      tester.widget<MxFocusRing>(find.byType(MxFocusRing)).radius,
      BorderRadius.circular(AppRadius.full),
    );

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.foregroundPainter is MxFocusRingPainter,
      ),
    );
    expect(
      (ring.foregroundPainter! as MxFocusRingPainter).color,
      MxSemanticColors.light.primaryForeground,
    );
  });

  testWidgets('pressed lays the label ink at the pressed alpha', (
    tester,
  ) async {
    Color? pressed(WidgetTester tester) => tester
        .widget<TextButton>(find.byType(TextButton))
        .style!
        .overlayColor!
        .resolve({WidgetState.pressed});

    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: false, onSelected: (_) {}),
    );
    expect(
      pressed(tester),
      scheme.onSurface.withValues(alpha: AppOpacity.pressed),
    );

    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: true, onSelected: (_) {}),
    );
    expect(
      pressed(tester),
      scheme.onPrimary.withValues(alpha: AppOpacity.pressed),
    );
  });
}
