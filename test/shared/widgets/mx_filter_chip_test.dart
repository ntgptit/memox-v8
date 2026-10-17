import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _chip = find.byType(FButton);

/// The ForUI outline extra-small button style the chip is built on.
FButtonStyle _style(WidgetTester tester) =>
    forUiTheme(tester, _chip).buttonStyles.outline.xs;

ShapeDecoration _resolved(WidgetTester tester, Set<FTappableVariant> states) =>
    _style(tester).decoration.resolve(states) as ShapeDecoration;

Color? _resolvedInk(WidgetTester tester, Set<FTappableVariant> states) =>
    _style(tester).contentStyle.textStyle.resolve(states).color;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  final colors = appLightColors;
  final selected = {FTappableVariant.selected};
  final disabled = {FTappableVariant.disabled};

  testWidgets('unselected: the outline variant, 32 tall inside a 48 target', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: false, onSelected: (_) {}),
    );

    expect(paintedRect(tester, _chip).height, 32);
    expect(paintedDecoration(tester, _chip).color, _resolved(tester, {}).color);
    expect(paintedSide(tester, _chip), isNot(BorderSide.none));
    expect(
      paintedSide(tester, _chip),
      (_resolved(tester, {}).shape as OutlinedBorder).side,
    );
    expect(textColor(tester, find.text('Due')), _resolvedInk(tester, {}));
    expect(find.byIcon(AppIcons.check), findsNothing);
  });

  testWidgets("selected: ForUI's selected look and a leading check", (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: true, onSelected: (_) {}),
    );

    expect(
      paintedDecoration(tester, _chip).color,
      _resolved(tester, selected).color,
    );
    expect(
      paintedSide(tester, _chip),
      (_resolved(tester, selected).shape as OutlinedBorder).side,
    );
    expect(textColor(tester, find.text('Due')), _resolvedInk(tester, selected));
    expect(find.byIcon(AppIcons.check), findsOneWidget);
    expect(
      iconColor(tester, find.byIcon(AppIcons.check)),
      _style(tester).contentStyle.iconStyle.resolve(selected).color,
    );
    // Selection shows in more than the leading check: the fill or the ink
    // differs from the resting chip.
    expect([
      _resolved(tester, selected).color,
      _resolvedInk(tester, selected),
    ], isNot([_resolved(tester, {}).color, _resolvedInk(tester, {})]));
  });

  // The label sits after the chip's padding, or after the padding, the glyph
  // and its gap.
  testWidgets('the label is inset by the padding, or by padding + glyph + '
      'gap', (tester) async {
    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Due this week',
        isSelected: false,
        onSelected: (_) {},
      ),
    );
    final content = _style(tester).contentStyle;
    final padding = content.padding.resolve(TextDirection.ltr);
    final bare = paintedRect(tester, _chip);
    expect(
      tester.getTopLeft(find.text('Due this week')).dx - bare.left,
      padding.left,
    );
    expect(
      bare.right - tester.getTopRight(find.text('Due this week')).dx,
      padding.right,
    );

    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Due this week',
        icon: AppIcons.filter,
        isSelected: false,
        onSelected: (_) {},
      ),
    );
    final left = paintedRect(tester, _chip).left;
    final glyph = tester.getSize(find.byIcon(AppIcons.filter)).width;
    expect(
      tester.getTopLeft(find.byIcon(AppIcons.filter)).dx - left,
      padding.left,
    );
    expect(
      tester.getTopLeft(find.text('Due this week')).dx - left,
      padding.left + glyph + content.spacing,
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

  testWidgets("keyboard focus draws ForUI's focus outline round the chip", (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: false, onSelected: (_) {}),
    );
    useKeyboardFocusHighlight();
    final outline = forUiTheme(tester, _chip).style.focusedOutlineStyle;
    expect(outline.color, colors.primary);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(
      focusRingRender(tester),
      paintsFocusRing(outline.color, width: outline.width),
    );
  });

  // M3F-03 (owner 2026-10-15, supersedes SW-REV-001): the count keeps the
  // label's foreground, so it meets 4.5:1; the meta role carries the quieter
  // hierarchy.
  for (final (name, isSelected, onSelected) in [
    ('resting', false, (bool _) {}),
    ('selected', true, (bool _) {}),
    ('disabled', false, null),
  ]) {
    testWidgets('the count keeps the label foreground, $name', (tester) async {
      await pumpMx(
        tester,
        MxFilterChip(
          label: 'Due',
          count: 12,
          isSelected: isSelected,
          onSelected: onSelected,
        ),
      );
      final states = {
        if (isSelected) FTappableVariant.selected,
        if (onSelected == null) FTappableVariant.disabled,
      };

      expect(textColor(tester, find.text('Due')), _resolvedInk(tester, states));
      expect(
        textColor(tester, find.text('12')),
        textColor(tester, find.text('Due')),
      );
      expect(
        tester.widget<Text>(find.text('12')).style!.fontSize,
        tester.element(find.text('12')).texts.meta.fontSize,
      );
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('M3F-03: the resting count is 4.5:1 on the page and a card '
        '(${brightness.name})', (tester) async {
      await pumpMx(
        tester,
        MxFilterChip(
          label: 'Due',
          count: 12,
          isSelected: false,
          onSelected: (_) {},
        ),
        brightness: brightness,
      );
      final context = tester.element(find.text('12'));
      final painted = textColor(tester, find.text('12'))!;

      for (final ground in [context.colors.background, context.colors.card]) {
        final ink = Color.alphaBlend(painted, ground);
        expect(_contrast(ink, ground), greaterThanOrEqualTo(4.5));
      }
    });
  }

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
    await tester.pumpAndSettle();

    expect(reported, isTrue);
  });

  testWidgets('selection is announced on the button node', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: true, onSelected: (_) {}),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Due')),
      matchesSemantics(
        label: 'Due',
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
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
    expect(tester.getSize(_chip).height, greaterThanOrEqualTo(48));
    await expectAccessibleTargets(tester);
  });

  // DEV-372: the button resolves its own disabled colours; a wrapper dimming
  // it again left a doubly faded chip.
  testWidgets('disabled paints the theme disabled colours, dimmed once', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxFilterChip(label: 'Cards', isSelected: false, onSelected: null),
    );

    expect(
      find.ancestor(of: _chip, matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(
      paintedDecoration(tester, _chip).color,
      _resolved(tester, disabled).color,
    );
    expect(
      textColor(tester, find.text('Cards')),
      _resolvedInk(tester, disabled),
    );
    expect(
      paintedSide(tester, _chip),
      (_resolved(tester, disabled).shape as OutlinedBorder).side,
    );

    await pumpMx(
      tester,
      const MxFilterChip(label: 'Cards', isSelected: true, onSelected: null),
    );
    final both = {FTappableVariant.selected, FTappableVariant.disabled};
    expect(
      paintedDecoration(tester, _chip).color,
      _resolved(tester, both).color,
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
    expect(tester.getSize(_chip).width, lessThanOrEqualTo(200));
  });

  // M3F-04: the leading glyph is read on a card; 3:1 for a glyph.
  for (final brightness in Brightness.values) {
    testWidgets('M3F-04: the leading glyph is 3:1 on a card '
        '(${brightness.name})', (tester) async {
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
      final glyph = iconColor(tester, find.byIcon(AppIcons.filter))!;

      expect(glyph, _style(tester).contentStyle.iconStyle.resolve({}).color);
      expect(_contrast(glyph, context.colors.card), greaterThan(3));
    });
  }
}
