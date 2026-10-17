import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

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

  testWidgets("tones paint ForUI's variants: fill, label and edge", (
    tester,
  ) async {
    final expected = {
      MxButtonTone.primary: (
        colors.primary,
        colors.primaryForeground,
        BorderSide.none,
      ),
      MxButtonTone.secondary: (
        colors.secondary,
        colors.secondaryForeground,
        BorderSide.none,
      ),
      MxButtonTone.outline: (
        colors.card,
        colors.secondaryForeground,
        BorderSide(color: colors.border),
      ),
      // ForUI's destructive is its soft tint, in the destructive colour.
      MxButtonTone.destructive: (
        colors.destructive.withValues(alpha: 0.1),
        colors.destructive,
        BorderSide.none,
      ),
    };
    for (final MapEntry(key: tone, value: (fill, ink, edge))
        in expected.entries) {
      await pumpMx(tester, MxButton(label: 'Go', tone: tone, onPressed: () {}));

      expect(paintedDecoration(tester, _button).color, fill, reason: '$tone');
      expect(textColor(tester, find.text('Go')), ink, reason: '$tone');
      expect(paintedSide(tester, _button), edge, reason: '$tone');
    }
  });

  testWidgets('text tone is the ghost: no fill and no edge', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Skip', tone: MxButtonTone.text, onPressed: () {}),
    );

    expect(paintedDecoration(tester, _button).color, isNull);
    expect(paintedSide(tester, _button), BorderSide.none);
    expect(textColor(tester, find.text('Skip')), colors.secondaryForeground);
  });

  testWidgets(
    'dangerTint paints the soft danger tint with the error label and edge '
    '(FE-A6 P2, screen 16a)',
    (tester) async {
      await pumpMx(
        tester,
        MxButton(
          label: 'Again',
          tone: MxButtonTone.dangerTint,
          onPressed: () {},
        ),
      );

      expect(
        paintedDecoration(tester, _button).color,
        colors.error.tintOver(colors.background),
      );
      expect(textColor(tester, find.text('Again')), colors.error);
      expect(paintedSide(tester, _button).color, colors.error);
    },
  );

  testWidgets(
    'warning paints the warning fill with its label, above 4.5:1 in both '
    'themes (spec D15)',
    (tester) async {
      await pumpMx(
        tester,
        MxButton(label: 'Merge', tone: MxButtonTone.warning, onPressed: () {}),
      );

      expect(
        paintedDecoration(tester, _button).color,
        MxStatusColors.light.warningFill,
      );
      expect(
        textColor(tester, find.text('Merge')),
        MxStatusColors.light.onWarningFill,
      );
      expect(paintedSide(tester, _button), BorderSide.none);
      for (final status in [MxStatusColors.light, MxStatusColors.dark]) {
        expect(
          _ratio(status.warningFill, status.onWarningFill),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );

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

  testWidgets('a loading button keeps its resting paint and width, spins, '
      'and takes no tap', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxButton(label: 'Save', onPressed: () => taps++, isLoading: true),
    );

    expect(paintedDecoration(tester, _button).color, colors.primary);
    await tester.tap(find.byType(MxButton), warnIfMissed: false);
    await tester.pump(const Duration(seconds: 1));
    expect(taps, 0);
    // The spinner keeps turning; take it off before the test ends.
    await tester.pumpWidget(const SizedBox());
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

  testWidgets('naturalWidth is the one-line label plus icon and padding', (
    tester,
  ) async {
    late double measured;
    const button = MxButton(
      label: 'Restore',
      icon: AppIcons.restore,
      onPressed: null,
    );
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          measured = button.naturalWidth(context);
          return const UnconstrainedBox(child: button);
        },
      ),
    );
    // Unconstrained, the button lays out at its natural width.
    expect(measured, tester.getSize(_button).width.ceilToDouble());
  });

  testWidgets('naturalWidth of a loading button still measures its label', (
    tester,
  ) async {
    late double idle;
    late double loading;
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          idle = MxButton(
            label: 'Save',
            onPressed: () {},
          ).naturalWidth(context);
          loading = MxButton(
            label: 'Save',
            isLoading: true,
            onPressed: () {},
          ).naturalWidth(context);
          return const SizedBox();
        },
      ),
    );
    expect(loading, idle);
  });

  testWidgets("a brand mark is painted at 18 in the icon's place, and "
      'TalkBack reads the label only', (tester) async {
    await pumpMx(
      tester,
      MxButton(
        label: 'Continue with Google',
        mark: const AssetImage('assets/brand/google_g.png'),
        onPressed: () {},
      ),
    );
    final image = find.byType(Image);
    final spacing = forUiTheme(
      tester,
      _button,
    ).buttonStyles.primary.lg.contentStyle.spacing;

    expect(tester.getSize(image), const Size.square(18));
    expect(
      tester.getRect(find.text('Continue with Google')).left -
          tester.getRect(image).right,
      spacing,
    );
    expect(tester.widget<Image>(image).excludeFromSemantics, isTrue);
    expect(find.bySemanticsLabel('Continue with Google'), findsOneWidget);
  });

  testWidgets('naturalWidth counts the brand mark and its gap', (tester) async {
    late double plain;
    late double marked;
    late double spacing;
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          spacing = FTheme.of(context)
              .buttonStyles
              .primary
              .lg
              .contentStyle
              .spacing;
          plain = MxButton(label: 'Go', onPressed: () {}).naturalWidth(context);
          marked = MxButton(
            label: 'Go',
            mark: const AssetImage('assets/brand/google_g.png'),
            onPressed: () {},
          ).naturalWidth(context);
          return const SizedBox();
        },
      ),
    );

    expect(marked - plain, 18 + spacing);
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
}

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}
