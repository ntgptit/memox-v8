import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

Material _material(WidgetTester tester) =>
    tester.widget<Material>(_painted.first);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('each size paints its height and keeps a 48 target', (
    tester,
  ) async {
    const heights = {
      MxButtonSize.regular: 48.0,
      MxButtonSize.small: 36.0,
      MxButtonSize.compact: 32.0,
      MxButtonSize.chip: 28.0,
      MxButtonSize.study: 48.0,
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

  testWidgets('tones paint their fill, ink and edge', (tester) async {
    final expected = {
      MxButtonTone.primary: (scheme.primary, scheme.onPrimary, BorderSide.none),
      MxButtonTone.secondary: (
        scheme.surfaceContainer,
        scheme.onSurface,
        BorderSide.none,
      ),
      MxButtonTone.destructive: (scheme.error, scheme.onError, BorderSide.none),
    };
    for (final MapEntry(key: tone, value: (fill, ink, edge))
        in expected.entries) {
      await pumpMx(tester, MxButton(label: 'Go', tone: tone, onPressed: () {}));
      final material = _material(tester);

      expect(material.color, fill, reason: '$tone');
      expect(material.textStyle!.color, ink, reason: '$tone');
      expect((material.shape! as RoundedRectangleBorder).side, edge);
    }
  });

  testWidgets('dangerSoft paints errorContainer with onErrorContainer and no '
      'edge (FE-A6 P2, screen 16a)', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Again', tone: MxButtonTone.dangerSoft, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color, scheme.errorContainer);
    expect(material.textStyle!.color, scheme.onErrorContainer);
    expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
  });

  testWidgets('warning paints the warning role with its ink, above 4.5:1 in '
      'both themes (spec D15)', (tester) async {
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
  });

  testWidgets('a detail line sits under the label in the button ink '
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

  testWidgets('outline tone has no fill, primaryForeground, 1px outline', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, MxSemanticColors.light.primaryForeground);
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide(color: scheme.outline),
    );
  });

  // Critique 2026-09-30 part 1 (R7): outlineVariant nearly vanished on the
  // dark sheet (1.05:1); the control edge is outline.
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

  testWidgets('the ghost tone edge is outline; the outline and text tones ink '
      'in primaryForeground; the primary pressed overlay is shadow at the '
      'pressed alpha; the focus ring is MxFocusRing', (tester) async {
    for (final brightness in Brightness.values) {
      final colors = brightness == Brightness.light
          ? AppColorSchemes.light
          : AppColorSchemes.dark;
      final semantic = brightness == Brightness.light
          ? MxSemanticColors.light
          : MxSemanticColors.dark;
      ButtonStyle style() =>
          tester.widget<TextButton>(find.byType(TextButton)).style!;
      await pumpMx(
        tester,
        MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(style().side!.resolve({})!.color, colors.outline);
      expect(style().foregroundColor!.resolve({}), semantic.primaryForeground);
      await pumpMx(
        tester,
        MxButton(label: 'Go', tone: MxButtonTone.text, onPressed: () {}),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(style().foregroundColor!.resolve({}), semantic.primaryForeground);
      await pumpMx(
        tester,
        MxButton(label: 'Go', onPressed: () {}),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(
        style().overlayColor!.resolve({WidgetState.pressed}),
        colors.shadow.withValues(alpha: AppOpacity.pressed),
      );
      // The ring is the shared one, never the Material side.
      expect(find.byType(MxFocusRing), findsOneWidget);
      expect(style().side!.resolve({WidgetState.focused}), BorderSide.none);
    }
  });

  testWidgets('chip size paints its own surface and outline edge (R2)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Tag', size: MxButtonSize.chip, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color, scheme.surfaceContainerLowest);
    expect(material.textStyle!.color, scheme.onSurface);
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide(color: scheme.outline),
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
  testWidgets('text tone has no fill and no edge, in primaryForeground', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Skip', tone: MxButtonTone.text, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, MxSemanticColors.light.primaryForeground);
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

  testWidgets('an unfilled tone presses through its ink', (tester) async {
    Color? pressed(WidgetTester tester) => tester
        .widget<TextButton>(find.byType(TextButton))
        .style!
        .overlayColor!
        .resolve({WidgetState.pressed});

    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
    );
    await tester.pumpAndSettle();
    expect(
      pressed(tester),
      MxSemanticColors.light.primaryForeground.withValues(
        alpha: AppOpacity.pressed,
      ),
    );

    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.text, onPressed: () {}),
    );
    await tester.pumpAndSettle();
    expect(
      pressed(tester),
      MxSemanticColors.light.primaryForeground.withValues(
        alpha: AppOpacity.pressed,
      ),
    );

    // The ghost is the chip size: it paints a fill, so it presses through
    // the shadow like every filled tone.
    await pumpMx(
      tester,
      MxButton(label: 'Go', size: MxButtonSize.chip, onPressed: () {}),
    );
    await tester.pumpAndSettle();
    expect(
      pressed(tester),
      AppColorSchemes.light.shadow.withValues(alpha: AppOpacity.pressed),
    );
  });
}

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}
