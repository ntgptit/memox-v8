import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';

import '../../support/theme_expect.dart';

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
  final scheme = lightColorScheme;

  testWidgets('each size paints its height and keeps a 48 target', (
    tester,
  ) async {
    const dimens = AppDimens();
    final heights = {
      MxButtonSize.regular: dimens.sizeButton,
      MxButtonSize.small: dimens.sizeButtonSmall,
      MxButtonSize.chip: dimens.sizeChip,
      MxButtonSize.study: dimens.sizeButton,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      await pumpMx(tester, MxButton(label: 'Go', size: size, onPressed: () {}));

      expect(tester.getSize(_painted.first).height, height, reason: '$size');
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48),
        reason: '$size',
      );
    }
  });

  testWidgets('tones paint their fill, foreground and edge', (tester) async {
    final expected = {
      MxButtonTone.primary: (scheme.primary, scheme.onPrimary, BorderSide.none),
      MxButtonTone.secondary: (
        scheme.surfaceContainer,
        scheme.onSurface,
        BorderSide.none,
      ),
      MxButtonTone.destructive: (
        lightColorScheme.error,
        lightColorScheme.onError,
        BorderSide.none,
      ),
    };
    for (final MapEntry(key: tone, value: (fill, ink, edge))
        in expected.entries) {
      await pumpMx(tester, MxButton(label: 'Go', tone: tone, onPressed: () {}));
      final material = _material(tester);

      expect(material.color, fill, reason: '$tone');
      expect(material.textStyle!.color, ink, reason: '$tone');
      expect((material.shape! as OutlinedBorder).side, edge);
    }
  });

  testWidgets(
    'dangerTint paints the soft danger tint with the error foreground '
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
      final material = _material(tester);

      expect(material.color, scheme.error.tintOver(scheme.surface));
      expect(material.textStyle!.color, scheme.error);
      expect(
        (material.shape! as OutlinedBorder).side,
        BorderSide(
          color: scheme.error,
          width: const AppDimens().strokeHairline,
        ),
      );
    },
  );

  testWidgets(
    'warning paints the warning role with its foreground, above 4.5:1 in '
    'both themes (spec D15)',
    (tester) async {
      await pumpMx(
        tester,
        MxButton(label: 'Merge', tone: MxButtonTone.warning, onPressed: () {}),
      );
      final material = _material(tester);

      expect(material.color, MxColorsExtension.light.warningContainer);
      expect(
        material.textStyle!.color,
        MxColorsExtension.light.onWarningContainer,
      );
      expect((material.shape! as OutlinedBorder).side, BorderSide.none);
      for (final colors in [MxColorsExtension.light, MxColorsExtension.dark]) {
        expect(
          _ratio(colors.warningContainer, colors.onWarningContainer),
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
    expect(DefaultTextStyle.of(context).style.color, scheme.onSurface);
    expect(
      tester.widget<Text>(find.text('6d')).style,
      context.texts.label,
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

  testWidgets('outline tone has no fill, the accent, 1px outline', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, accentOf(scheme));
    expect(
      (material.shape! as OutlinedBorder).side,
      BorderSide(
        color: scheme.outline,
        width: const AppDimens().strokeHairline,
      ),
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
      (_material(tester).shape! as OutlinedBorder).side,
      BorderSide(
        color: darkColorScheme.outline,
        width: const AppDimens().strokeHairline,
      ),
    );
  });

  testWidgets('chip size is the flat unselected chip: no fill, 8 corners', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Tag', size: MxButtonSize.chip, onPressed: () {}),
    );
    final material = _material(tester);

    expect(tester.getSize(_painted.first).height, 32);
    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, scheme.onSurfaceVariant);
    expect(
      (material.shape! as MxFocusRingBorder).base,
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Tag')).dx -
          tester.getTopLeft(_painted.first).dx,
      16,
    );
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

  testWidgets('disabled follows the disabled opacities and ignores taps', (
    tester,
  ) async {
    await pumpMx(tester, const MxButton(label: 'Go', onPressed: null));
    final context = tester.element(find.text('Go'));
    final style = tester.widget<TextButton>(find.byType(TextButton)).style!;

    expect(
      style.foregroundColor!.resolve({WidgetState.disabled}),
      context.colors.foreground.withValues(
        alpha: context.colors.disabledOpacity,
      ),
    );
    expect(
      style.backgroundColor!.resolve({WidgetState.disabled}),
      context.colors.foreground.withValues(
        alpha: context.dimens.opacityDisabledContainer,
      ),
    );
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
  testWidgets('text tone has no fill and no edge, in the accent', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Skip', tone: MxButtonTone.text, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, accentOf(scheme));
    expect((material.shape! as OutlinedBorder).side, BorderSide.none);
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
    expect(
      tester.getRect(find.text('Continue with Google')).left -
          tester.getRect(image).right,
      const AppDimens().space8,
    );
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

    // The mark and its 8 gap, less the 8 a leading glyph takes off the start
    // padding (24 to 16).
    const dimens = AppDimens();
    expect(
      marked - plain,
      18 + dimens.space8 - (dimens.space24 - dimens.space16),
    );
  });
}

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}
