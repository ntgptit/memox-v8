import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

// What MxButton measures and paints around its label: the side padding per
// tone, the leading glyph and its gap, and the focus outline. ForUI owns the
// numbers; the tests read them from the theme's button style.

final _button = find.byType(FButton);

/// The ForUI style [tone] is built on, at the large touch size. The soft
/// danger and warning tones are ForUI's size styles with their own colours,
/// so their geometry is the primary button's.
FButtonStyle _style(WidgetTester tester, MxButtonTone tone) {
  final styles = forUiTheme(tester, _button).buttonStyles;
  return switch (tone) {
    MxButtonTone.secondary => styles.secondary,
    MxButtonTone.outline => styles.outline,
    MxButtonTone.text => styles.ghost,
    MxButtonTone.destructive => styles.destructive,
    MxButtonTone.primary ||
    MxButtonTone.dangerTint ||
    MxButtonTone.warning => styles.primary,
  }.lg;
}

void main() {
  testWidgets('a leading glyph is painted at the style icon size, one gap '
      'before the label', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Add', icon: AppIcons.add, onPressed: () {}),
    );
    final content = _style(tester, MxButtonTone.primary).contentStyle;

    expect(
      tester.getSize(find.byIcon(AppIcons.add)),
      Size.square(content.iconStyle.resolve({}).size!),
    );
    expect(
      tester.getRect(find.text('Add')).left -
          tester.getRect(find.byIcon(AppIcons.add)).right,
      content.spacing,
    );
  });

  testWidgets('horizontal padding is the style padding, per tone', (
    tester,
  ) async {
    for (final tone in MxButtonTone.values) {
      await pumpMx(
        tester,
        MxButton(label: 'Save changes', tone: tone, onPressed: () {}),
      );
      final box = paintedRect(tester, _button);
      final label = tester.getRect(find.text('Save changes'));
      final padding = _style(
        tester,
        tone,
      ).contentStyle.padding.resolve(TextDirection.ltr);

      expect(label.left - box.left, padding.left, reason: '$tone start');
      expect(box.right - label.right, padding.right, reason: '$tone end');
    }
  });

  // A leading glyph sits at the start padding, the label after it and its
  // gap, and the end side keeps the padding.
  testWidgets('with a leading glyph the glyph starts at the padding, the '
      'label follows one gap after it', (tester) async {
    for (final tone in MxButtonTone.values) {
      await pumpMx(
        tester,
        MxButton(label: 'Go', tone: tone, icon: AppIcons.add, onPressed: () {}),
      );
      final box = paintedRect(tester, _button);
      final glyph = tester.getRect(find.byIcon(AppIcons.add));
      final label = tester.getRect(find.text('Go'));
      final content = _style(tester, tone).contentStyle;
      final padding = content.padding.resolve(TextDirection.ltr);

      expect(glyph.left - box.left, padding.left, reason: '$tone start');
      expect(label.left - glyph.right, content.spacing, reason: '$tone gap');
      expect(box.right - label.right, padding.right, reason: '$tone end');
    }
  });

  testWidgets("a focused button draws ForUI's focus outline, on a primary "
      'fill too', (tester) async {
    for (final tone in MxButtonTone.values) {
      await pumpMx(
        tester,
        MxButton(
          label: 'Go',
          tone: tone,
          isAutofocused: true,
          onPressed: () {},
        ),
      );
      useKeyboardFocusHighlight();
      await tester.pumpAndSettle();
      final outline = forUiTheme(tester, _button).style.focusedOutlineStyle;

      expect(
        focusRingRender(tester),
        paintsFocusRing(outline.color, width: outline.width),
        reason: '$tone',
      );
    }
  });

  testWidgets('an unfocused button paints no outline', (tester) async {
    await pumpMx(tester, MxButton(label: 'Go', onPressed: () {}));
    final outline = forUiTheme(tester, _button).style.focusedOutlineStyle;
    final ring = find.descendant(
      of: _button,
      matching: find.byType(FFocusedOutline),
    );

    expect(
      tester.renderObject(ring.first),
      isNot(paintsFocusRing(outline.color, width: outline.width)),
    );
  });
}
