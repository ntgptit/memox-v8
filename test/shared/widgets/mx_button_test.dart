import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/contrast.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _button = find.byType(FButton);

void main() {
  final colors = appLightColors;

  testWidgets('each size paints its height and keeps a 48 target', (
    tester,
  ) async {
    final heights = {
      MxButtonSize.regular: 48.0,
      MxButtonSize.small: 40.0,
      MxButtonSize.chip: 32.0,
      MxButtonSize.study: 48.0,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      await pumpMx(tester, MxButton(label: 'Go', size: size, onPressed: () {}));

      expect(paintedRect(tester, _button).height, height, reason: '$size');
      expect(
        tester.getSize(_button).height,
        greaterThanOrEqualTo(48),
        reason: '$size',
      );
    }
  });

  // One case per tone: the fill, the label ink and the edge ForUI paints.
  final tones =
      <
        ({
          MxButtonTone tone,
          String label,
          String note,
          Object? fill,
          Color ink,
          Matcher edge,
        })
      >[
        (
          tone: MxButtonTone.primary,
          label: 'Go',
          note: '',
          fill: colors.primary,
          ink: colors.primaryForeground,
          edge: equals(BorderSide.none),
        ),
        (
          tone: MxButtonTone.secondary,
          label: 'Go',
          note: '',
          fill: colors.secondary,
          ink: colors.secondaryForeground,
          edge: equals(BorderSide.none),
        ),
        (
          tone: MxButtonTone.outline,
          label: 'Go',
          note: '',
          fill: colors.card,
          ink: colors.secondaryForeground,
          edge: equals(BorderSide(color: colors.border)),
        ),
        // ForUI's destructive is its soft tint, in the destructive colour.
        (
          tone: MxButtonTone.destructive,
          label: 'Go',
          note: '',
          fill: colors.destructive.withValues(alpha: 0.1),
          ink: colors.destructive,
          edge: equals(BorderSide.none),
        ),
        // The ghost: no fill and no edge.
        (
          tone: MxButtonTone.text,
          label: 'Skip',
          note: '',
          fill: isNull,
          ink: colors.secondaryForeground,
          edge: equals(BorderSide.none),
        ),
        // The soft danger tint with the error label and edge.
        (
          tone: MxButtonTone.dangerTint,
          label: 'Again',
          note: ' (FE-A6 P2, screen 16a)',
          fill: colors.error.tintOver(colors.background),
          ink: colors.error,
          edge: isA<BorderSide>().having((s) => s.color, 'color', colors.error),
        ),
        // The warning fill with its label (its contrast is pinned below).
        (
          tone: MxButtonTone.warning,
          label: 'Merge',
          note: ' (spec D15)',
          fill: MxStatusColors.light.warningFill,
          ink: MxStatusColors.light.onWarningFill,
          edge: equals(BorderSide.none),
        ),
      ];
  for (final c in tones) {
    testWidgets("tones paint ForUI's variants: ${c.tone.name} fill, label and "
        'edge${c.note}', (tester) async {
      await pumpMx(
        tester,
        MxButton(label: c.label, tone: c.tone, onPressed: () {}),
      );

      expect(paintedDecoration(tester, _button).color, c.fill);
      expect(textColor(tester, find.text(c.label)), c.ink);
      expect(paintedSide(tester, _button), c.edge);
    });
  }

  test('warning fill and label read above 4.5:1 in both themes (spec D15)', () {
    for (final status in [MxStatusColors.light, MxStatusColors.dark]) {
      expect(
        contrastRatio(status.warningFill, status.onWarningFill),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('a detail line sits under the label in the button foreground '
      '(FE-A6 P2, screen 16a)', (tester) async {
    await pumpMx(
      tester,
      MxButton(
        label: 'Good',
        detail: '6d',
        tone: MxButtonTone.secondary,
        onPressed: () {},
      ),
    );
    final context = tester.element(find.text('6d'));

    expect(
      tester.getRect(find.text('6d')).top,
      greaterThanOrEqualTo(tester.getRect(find.text('Good')).bottom),
    );
    expect(textColor(tester, find.text('6d')), colors.secondaryForeground);
    expect(
      tester.widget<Text>(find.text('6d')).style!.fontSize,
      context.texts.label.fontSize,
    );
  });

  test('a detail line needs a size with room for it', () {
    expect(
      () => MxButton(
        label: 'Go',
        detail: '6d',
        size: MxButtonSize.chip,
        onPressed: () {},
      ),
      throwsAssertionError,
    );
  });

  test('a glyph or a mark, not both', () {
    expect(
      () => MxButton(
        label: 'Go',
        icon: AppIcons.add,
        mark: const AssetImage('assets/brand/google_g.png'),
        onPressed: () {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('dark: the outline edge is the dark border', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
      brightness: Brightness.dark,
    );
    expect(paintedSide(tester, _button).color, appDarkColors.border);
  });

  testWidgets('isAutofocused takes the focus when it shows', (tester) async {
    await pumpMx(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxButton(label: 'Delete', onPressed: () {}),
          MxButton(label: 'Keep', onPressed: () {}, isAutofocused: true),
        ],
      ),
    );
    await tester.pump();

    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(focused.findAncestorWidgetOfExactType<MxButton>()?.label, 'Keep');
  });

  testWidgets('a tap calls onPressed', (tester) async {
    var taps = 0;
    await pumpMx(tester, MxButton(label: 'Go', onPressed: () => taps++));
    await tester.tap(find.byType(MxButton));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets("disabled takes ForUI's disabled paint, ignores taps and says "
      'so', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxButton(label: 'Go', onPressed: null));

    expect(
      paintedDecoration(tester, _button).color,
      colors.disable(colors.primary),
    );
    expect(
      textColor(tester, find.text('Go')),
      colors.disable(colors.primaryForeground),
    );
    // ForUI's tappable reports a selected state too: never selected here.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Go')),
      matchesSemantics(
        label: 'Go',
        isButton: true,
        hasEnabledState: true,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('block fills the parent width', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxButton(label: 'Save', isBlock: true, onPressed: () {}),
      ),
    );

    expect(tester.getSize(_button).width, 300);
  });

  testWidgets('small painted sizes still offer 48×48 labelled targets', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxButton(label: 'Pick', size: MxButtonSize.small, onPressed: () {}),
          MxButton(label: 'Undo', size: MxButtonSize.small, onPressed: () {}),
          MxButton(label: 'Tag', size: MxButtonSize.chip, onPressed: () {}),
        ],
      ),
    );

    await expectAccessibleTargets(tester);
  });

  testWidgets('isSingleLine keeps a long label on one line', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 120,
        child: MxButton(
          label: 'Delete for good forever',
          isBlock: true,
          isSingleLine: true,
          onPressed: () {},
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Delete for good forever'));
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
  });

  testWidgets('a regular label wraps to two lines in a narrow column', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 120,
        child: MxButton(
          label: 'Delete for good forever',
          isBlock: true,
          onPressed: () {},
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Delete for good forever')).maxLines,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('semanticLabel replaces the label on one node that keeps the '
      'tap and the enabled state (SW-REV-005)', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxButton(
        label: '07:30',
        semanticLabel: 'Reminder time, 07:30',
        onPressed: () => taps++,
      ),
    );

    expect(find.bySemanticsLabel('Reminder time, 07:30'), findsOneWidget);
    expect(find.bySemanticsLabel('07:30'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reminder time, 07:30')),
      matchesSemantics(
        label: 'Reminder time, 07:30',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Reminder time, 07:30'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('semanticLabel on a small button: one node with the label, the '
      'tap and the state, enabled or disabled (SW-REV-005)', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxButton(
        label: '20:00',
        semanticLabel: 'Reminder time, 20:00',
        size: MxButtonSize.small,
        onPressed: () {},
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reminder time, 20:00')),
      isSemantics(
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
      ),
    );

    await pumpMx(
      tester,
      const MxButton(
        label: '20:00',
        semanticLabel: 'Reminder time, 20:00',
        size: MxButtonSize.small,
        onPressed: null,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reminder time, 20:00')),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });
}
