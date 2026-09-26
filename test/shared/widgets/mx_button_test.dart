import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

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
      MxButtonTone.destructive: (
        MxSemanticColors.light.errorFill,
        MxSemanticColors.light.onErrorFill,
        BorderSide.none,
      ),
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

  testWidgets('dangerSoft paints the soft danger tint with the error ink '
      '(FE-A6 P2, screen 16a)', (tester) async {
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    await pumpMx(
      tester,
      MxButton(label: 'Again', tone: MxButtonTone.dangerSoft, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color, derived.dangerSoft);
    expect(material.textStyle!.color, scheme.error);
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide(color: derived.dangerBorder),
    );
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

  testWidgets('a detail line grows the box at 2x text instead of clipping', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 80,
        child: MxButton(
          label: 'Good',
          detail: '6d',
          isBlock: true,
          onPressed: () {},
        ),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(_painted.first).height, greaterThan(48));
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

  testWidgets('outline tone has no fill, primary ink, 1px outlineVariant', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, scheme.primary);
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide(color: scheme.outlineVariant),
    );
  });

  testWidgets('chip size paints its own surface and ghost edge (R2)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Tag', size: MxButtonSize.chip, onPressed: () {}),
    );
    final material = _material(tester);
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);

    expect(material.color, scheme.surfaceContainerLowest);
    expect(material.textStyle!.color, scheme.onSurface);
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide(color: derived.ghostBorder),
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

  testWidgets('loading keeps the width, shows a spinner and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(tester, MxButton(label: 'Save changes', onPressed: () {}));
    final restingWidth = tester.getSize(_painted.first).width;

    await pumpMx(
      tester,
      MxButton(label: 'Save changes', isLoading: true, onPressed: () => taps++),
    );
    await tester.tap(find.byType(MxButton), warnIfMissed: false);

    expect(tester.getSize(_painted.first).width, restingWidth);
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(taps, 0);
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

  testWidgets('a constrained label wraps and grows the box at 2x text', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 160,
        child: MxButton(
          label: 'Move every selected card',
          isBlock: true,
          onPressed: () {},
        ),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(_painted.first).height, greaterThan(48));
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

  testWidgets('loading: a filled button spins onPrimary, outline primary', (
    tester,
  ) async {
    for (final (tone, isOnFill) in [
      (MxButtonTone.primary, true),
      (MxButtonTone.destructive, true),
      (MxButtonTone.secondary, false),
      (MxButtonTone.outline, false),
    ]) {
      await pumpMx(
        tester,
        MxButton(label: 'Save', tone: tone, isLoading: true, onPressed: () {}),
      );

      expect(
        tester.widget<MxSpinner>(find.byType(MxSpinner)).isOnFill,
        isOnFill,
      );
    }
  });

  testWidgets('a loading button keeps its name for TalkBack', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxButton(label: 'Save', isLoading: true, onPressed: () {}),
    );

    expect(find.bySemanticsLabel('Save'), findsOneWidget);
    handle.dispose();
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

  testWidgets('naturalWidth grows with the text scale', (tester) async {
    late double atOne;
    late double atTwo;
    final button = MxButton(label: 'Restore', onPressed: () {});
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          atOne = button.naturalWidth(context);
          return button;
        },
      ),
    );
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          atTwo = button.naturalWidth(context);
          return button;
        },
      ),
      textScale: 2,
    );
    expect(atTwo, greaterThan(atOne));
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
}
