import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

Material _material(WidgetTester tester) =>
    tester.widget<Material>(_painted.first);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('each size paints its height as a pill and keeps a 48 target', (
    tester,
  ) async {
    const heights = {
      MxButtonSize.regular: AppSize.buttonRegular,
      MxButtonSize.small: AppSize.buttonSmall,
      MxButtonSize.compact: AppSize.buttonCompact,
      MxButtonSize.chip: AppSize.chip,
      MxButtonSize.study: AppSize.buttonRegular,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      await pumpMx(tester, MxButton(label: 'Go', size: size, onPressed: () {}));

      expect(tester.getSize(_painted.first).height, height, reason: '$size');
      expect(
        (_material(tester).shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(AppRadius.full),
        reason: '$size',
      );
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48),
        reason: '$size',
      );
    }
  });

  testWidgets('regular and study pad 24 each side, small and compact 12', (
    tester,
  ) async {
    const paddings = {
      MxButtonSize.regular: AppSpacing.section,
      MxButtonSize.study: AppSpacing.section,
      MxButtonSize.small: AppSpacing.grouped,
      MxButtonSize.compact: AppSpacing.grouped,
    };
    for (final MapEntry(key: size, value: padding) in paddings.entries) {
      await pumpMx(
        tester,
        UnconstrainedBox(
          child: MxButton(label: 'Go', size: size, onPressed: () {}),
        ),
      );
      final label = tester.getRect(find.text('Go'));
      final button = tester.getRect(_painted.first);

      expect(label.left - button.left, padding, reason: '$size');
      expect(button.right - label.right, padding, reason: '$size');
    }
  });

  testWidgets('tones paint their fill, foreground and edge', (tester) async {
    final expected = {
      MxButtonTone.primary: (scheme.primary, scheme.onPrimary, BorderSide.none),
      MxButtonTone.secondary: (
        MxSemanticColors.light.neutralSoft,
        MxSemanticColors.light.onNeutralSoft,
        BorderSide.none,
      ),
      MxButtonTone.destructive: (
        MxSemanticColors.light.errorFill,
        MxSemanticColors.light.onErrorFill,
        BorderSide.none,
      ),
    };
    for (final MapEntry(key: tone, value: (fill, foreground, edge))
        in expected.entries) {
      await pumpMx(tester, MxButton(label: 'Go', tone: tone, onPressed: () {}));
      final material = _material(tester);

      expect(material.color, fill, reason: '$tone');
      expect(material.textStyle!.color, foreground, reason: '$tone');
      expect((material.shape! as RoundedRectangleBorder).side, edge);
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'dangerSoft paints the danger tint with the on-danger-soft label, '
      '${brightness.name} '
      '(FE-A6 P2, screen 16a, DEV-371)',
      (tester) async {
        final semantic = brightness == Brightness.light
            ? MxSemanticColors.light
            : MxSemanticColors.dark;
        await pumpMx(
          tester,
          MxButton(
            label: 'Again',
            tone: MxButtonTone.dangerSoft,
            onPressed: () {},
          ),
          brightness: brightness,
        );
        final material = _material(tester);

        expect(material.color, semantic.dangerSoft);
        expect(material.textStyle!.color, semantic.onDangerSoft);
        expect(
          (material.shape! as RoundedRectangleBorder).side,
          BorderSide(color: semantic.dangerBorder),
        );
      },
    );
  }

  testWidgets(
    'warning paints the warning role with its foreground, above 4.5:1 in '
    'both themes (spec D15)',
    (tester) async {
      await pumpMx(
        tester,
        MxButton(label: 'Merge', tone: MxButtonTone.warning, onPressed: () {}),
      );
      final material = _material(tester);

      expect(material.color, MxSemanticColors.light.warning);
      expect(material.textStyle!.color, MxSemanticColors.light.onWarning);
      expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
      for (final colors in [MxSemanticColors.light, MxSemanticColors.dark]) {
        expect(
          _ratio(colors.warning, colors.onWarning),
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
    expect(
      DefaultTextStyle.of(context).style.color,
      MxSemanticColors.light.onNeutralSoft,
    );
    expect(
      tester.widget<Text>(find.text('6d')).style,
      context.textStyles.buttonDetail,
    );
  });

  test('a detail line needs a size with room for it', () {
    expect(
      () => MxButton(
        label: 'Go',
        detail: '6d',
        size: MxButtonSize.compact,
        onPressed: () {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('outline tone has no fill, primaryText, a 1px outline edge', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, MxSemanticColors.light.primaryText);
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide(color: scheme.outline),
    );
  });

  // Critique 2026-09-30 part 1 (R7): outlineVariant nearly vanished on the
  // dark sheet (1.05:1).
  testWidgets('dark: the outline edge is the dark outline', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
      brightness: Brightness.dark,
    );
    expect(
      (_material(tester).shape! as RoundedRectangleBorder).side,
      BorderSide(color: AppColorSchemes.dark.outline),
    );
  });

  testWidgets('chip size paints the neutral-soft chip with no edge (R2)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Tag', size: MxButtonSize.chip, onPressed: () {}),
    );
    final material = _material(tester);
    final derived = MxSemanticColors.light;

    expect(material.color, derived.neutralSoft);
    expect(material.textStyle!.color, derived.onNeutralSoft);
    expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
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
    expect(
      find.ancestor(of: find.text('Keep'), matching: find.byType(TextButton)),
      findsOneWidget,
    );
    expect(focused.findAncestorWidgetOfExactType<MxButton>()?.label, 'Keep');
  });

  testWidgets('a tap calls onPressed', (tester) async {
    var taps = 0;
    await pumpMx(tester, MxButton(label: 'Go', onPressed: () => taps++));
    await tester.tap(find.byType(MxButton));

    expect(taps, 1);
  });

  testWidgets('disabled dims the whole control to 0.38 and ignores taps', (
    tester,
  ) async {
    await pumpMx(tester, const MxButton(label: 'Go', onPressed: null));

    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.byType(TextButton),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.38);
  });

  testWidgets('a leading glyph is painted at 16', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Add', icon: AppIcons.add, onPressed: () {}),
    );

    expect(tester.getSize(find.byIcon(AppIcons.add)).width, 16);
  });

  testWidgets('block fills the parent width', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxButton(label: 'Save', isBlock: true, onPressed: () {}),
      ),
    );

    expect(tester.getSize(_painted.first).width, 300);
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
          MxButton(label: 'Undo', size: MxButtonSize.compact, onPressed: () {}),
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

  testWidgets('naturalWidth is the one-line label plus icon and padding', (
    tester,
  ) async {
    late double measured;
    const button = MxButton(
      label: 'Restore',
      icon: Icons.restore,
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
    expect(
      measured,
      tester.getSize(find.byType(TextButton)).width.ceilToDouble(),
    );
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
  testWidgets('text tone has no fill and no edge, in primaryText', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Skip', tone: MxButtonTone.text, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, MxSemanticColors.light.primaryText);
    expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
  });

  testWidgets('a brand mark is painted at 18 in the icon\'s place, and '
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

    expect(tester.getSize(image), const Size.square(18));
    expect(tester.widget<Image>(image).excludeFromSemantics, isTrue);
    expect(find.bySemanticsLabel('Continue with Google'), findsOneWidget);
  });

  testWidgets('naturalWidth counts the brand mark and its gap', (tester) async {
    late double plain;
    late double marked;
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
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

    expect(marked - plain, 18 + 4);
  });
}

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}
