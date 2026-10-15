import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/core/theme/mastery_ramp.dart';

import '../../support/theme_expect.dart';

// The Material component themes carry the Design System defaults, so a raw
// Material widget, or one the framework builds, looks like MemoX. Sizes and
// colours are read from the tokens, never restated.
void main() {
  const dimens = AppDimens();

  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    final scheme = theme.colorScheme;
    final mx = theme.extension<MxColorsExtension>()!;

    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: child)),
      ),
    );

    group(name, () {
      test('card: tonal surface, medium radius, no border, no shadow', () {
        final card = theme.cardTheme;
        expect(card.color, mx.cardSurface);
        expect(card.elevation, 0);
        final shape = card.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(dimens.radiusMd));
        expect(shape.side, BorderSide.none);
      });

      test('search bar and divider use their own surfaces', () {
        expect(
          theme.searchBarTheme.backgroundColor!.resolve({}),
          mx.searchSurface,
        );
        expect(theme.searchBarTheme.constraints!.minHeight, dimens.sizeSearch);
        expect(theme.dividerTheme.color, mx.divider);
        expect(theme.dividerTheme.thickness, dimens.strokeHairline);
      });

      test(
        'outlined and text buttons ink in the accent; filled keeps primary',
        () {
          final accent = name == 'light'
              ? scheme.primary
              : scheme.primaryFixedDim;
          for (final style in [
            theme.outlinedButtonTheme.style!,
            theme.textButtonTheme.style!,
          ]) {
            expect(style.foregroundColor!.resolve({}), accent);
            // The focus ring rides on the shape, offset from the container.
            final ring =
                style.shape!.resolve({WidgetState.focused})!
                    as MxFocusRingBorder;
            expect(ring.ring.color, scheme.primary);
            expect(ring.ring.width, dimens.strokeFocus);
            expect(ring.gap, dimens.strokeFocusGap);
            expect(
              (style.shape!.resolve({})! as MxFocusRingBorder).ring,
              BorderSide.none,
            );
            expect(style.iconSize!.resolve({}), dimens.sizeIconButton);
          }
          // Material 3 text button: 12 on the sides; the others keep 24.
          expect(
            theme.textButtonTheme.style!.padding!.resolve({}),
            EdgeInsets.symmetric(horizontal: dimens.space12),
          );
          expect(
            theme.outlinedButtonTheme.style!.padding!.resolve({}),
            EdgeInsets.symmetric(horizontal: dimens.space24),
          );
          expect(
            theme.filledButtonTheme.style!.padding!.resolve({}),
            EdgeInsets.symmetric(horizontal: dimens.space24),
          );
          expect(
            theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
            scheme.primary,
          );
        },
      );

      test('a disabled button follows the disabled opacities', () {
        final filled = theme.filledButtonTheme.style!;
        const disabled = {WidgetState.disabled};
        expect(
          filled.foregroundColor!.resolve(disabled),
          scheme.onSurface.withValues(alpha: dimens.opacityDisabledContent),
        );
        expect(
          filled.backgroundColor!.resolve(disabled),
          scheme.onSurface.withValues(alpha: dimens.opacityDisabledContainer),
        );
        // The whole control dims: an outline's edge too.
        expect(
          theme.outlinedButtonTheme.style!.side!.resolve(disabled)!.color,
          scheme.onSurface.withValues(alpha: dimens.opacityDisabledContainer),
        );
      });

      test('navigation: bar and rail sizes, the secondary-container pill', () {
        expect(theme.navigationBarTheme.height, dimens.sizeNav);
        expect(theme.navigationBarTheme.backgroundColor, scheme.surface);
        expect(
          theme.navigationBarTheme.indicatorColor,
          scheme.secondaryContainer,
        );
        expect(theme.navigationRailTheme.minWidth, dimens.sizeRail);
        expect(
          theme.navigationRailTheme.indicatorColor,
          scheme.secondaryContainer,
        );
      });

      // The Mx indicators paint their own colours (MxSpinner the accent,
      // MxLinearProgress the success container or the mastery ramp); the
      // theme keeps no fill of its own, so a framework indicator takes
      // Material 3's `primary`, and only the track agrees with them.
      test('progress: a track tall on the highest container, no fill', () {
        final progress = theme.progressIndicatorTheme;
        expect(progress.linearMinHeight, dimens.sizeTrack);
        expect(progress.color, isNull);
        expect(progress.linearTrackColor, MasteryRamp.track(scheme));
        expect(progress.circularTrackColor, MasteryRamp.track(scheme));
      });

      // The Mx chips read this theme: Material 3's flat filter chip.
      test('chip: flat, an 8 corner, secondaryContainer when selected', () {
        final chip = theme.chipTheme;
        const selected = {WidgetState.selected};

        expect(chip.color!.resolve({}), isNull);
        expect(chip.color!.resolve(selected), scheme.secondaryContainer);
        final edge = chip.side! as WidgetStateBorderSide;
        expect(
          edge.resolve({}),
          BorderSide(
            color: scheme.outlineVariant,
            width: dimens.strokeHairline,
          ),
        );
        expect(edge.resolve(selected), BorderSide.none);
        expect(
          chip.shape,
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dimens.radiusSm),
          ),
        );
        expect(chip.labelStyle!.color, scheme.onSurfaceVariant);
        expect(chip.secondaryLabelStyle!.color, scheme.onSecondaryContainer);
        expect(chip.checkmarkColor, scheme.onSecondaryContainer);
        // M3F-04: the glyph reads the accent, as every other glyph slot does
        // (`primary` is 3.01:1 on the dark page, 2.38:1 on a card).
        expect(chip.iconTheme!.color, accentOf(scheme));
        expect(chip.iconTheme!.size, dimens.sizeIconButton);
        expect(chip.padding, EdgeInsets.all(dimens.space8));
        expect(
          chip.labelPadding,
          EdgeInsets.symmetric(horizontal: dimens.space8),
        );
      });

      // MxToggle is a Material Switch that reads this theme: Material 3's
      // 52x32 switch.
      test('switch: M3 handle and track colours per state', () {
        final sw = theme.switchTheme;
        const on = {WidgetState.selected};
        const off = <WidgetState>{};
        const disabledOn = {WidgetState.selected, WidgetState.disabled};
        const disabledOff = {WidgetState.disabled};

        expect(sw.thumbColor!.resolve(on), scheme.onPrimary);
        expect(sw.thumbColor!.resolve(off), scheme.outline);
        // M3F-15: the engaged on handle stays onPrimary; primaryContainer
        // equals the primary track in this palette and hid the handle.
        expect(
          sw.thumbColor!.resolve({...on, WidgetState.pressed}),
          scheme.onPrimary,
        );
        expect(
          sw.thumbColor!.resolve({WidgetState.focused}),
          scheme.onSurfaceVariant,
        );
        expect(sw.trackColor!.resolve(on), scheme.primary);
        expect(sw.trackColor!.resolve(off), scheme.surfaceContainerHighest);
        // Disabled: the track is 12%, the unselected handle 38%.
        expect(
          sw.trackColor!.resolve(disabledOn),
          scheme.onSurface.withValues(alpha: dimens.opacityDisabledContainer),
        );
        expect(
          sw.trackColor!.resolve(disabledOff),
          scheme.surfaceContainerHighest.withValues(
            alpha: dimens.opacityDisabledContainer,
          ),
        );
        expect(sw.thumbColor!.resolve(disabledOn), scheme.surface);
        expect(
          sw.thumbColor!.resolve(disabledOff),
          scheme.onSurface.withValues(alpha: dimens.opacityDisabledContent),
        );
      });

      test('switch: a 2 outline edge off, none on, a 48 box', () {
        final sw = theme.switchTheme;

        expect(sw.trackOutlineWidth!.resolve({}), dimens.strokeControl);
        expect(sw.trackOutlineColor!.resolve({}), scheme.outline);
        expect(
          sw.trackOutlineColor!.resolve({WidgetState.selected}),
          Colors.transparent,
        );
        expect(
          sw.trackOutlineColor!.resolve({WidgetState.disabled}),
          scheme.onSurface.withValues(alpha: dimens.opacityDisabledContainer),
        );
        expect(sw.materialTapTargetSize, MaterialTapTargetSize.padded);
      });

      // MxSegmentedTray is a Material SegmentedButton that reads this theme.
      // Tokens keep secondaryContainer off buttons, so no segment is filled.
      test('segmented button: outline edge, accent label, check, no fill', () {
        final seg = theme.segmentedButtonTheme;
        final style = seg.style!;
        final accent = name == 'light'
            ? scheme.primary
            : scheme.primaryFixedDim;
        const chosen = {WidgetState.selected};

        expect(style.foregroundColor!.resolve(chosen), accent);
        expect(style.foregroundColor!.resolve({}), scheme.onSurface);
        expect(
          style.foregroundColor!.resolve({WidgetState.disabled}),
          scheme.onSurface.withValues(alpha: dimens.opacityDisabledContent),
        );
        // A null slot falls back to the SDK default, which fills the chosen
        // segment with secondaryContainer: the slot must say transparent.
        for (final states in [
          <WidgetState>{},
          chosen,
          {WidgetState.disabled},
          {WidgetState.disabled, WidgetState.selected},
        ]) {
          expect(style.backgroundColor!.resolve(states), Colors.transparent);
        }
        expect(style.side!.resolve({})?.color, scheme.outline);
        expect(style.side!.resolve({})?.width, dimens.strokeHairline);
        expect(
          style.side!.resolve({WidgetState.disabled})?.color,
          scheme.onSurface.withValues(alpha: dimens.opacityDisabledContainer),
        );
        expect(style.iconSize!.resolve({}), dimens.sizeIconButton);
        expect(style.tapTargetSize, MaterialTapTargetSize.padded);
        expect(style.textStyle!.resolve({}), theme.textTheme.labelLarge);
        expect((seg.selectedIcon! as Icon).icon, AppIcons.check);
      });

      test('segmented button: state layers and the offset focus ring', () {
        final style = theme.segmentedButtonTheme.style!;
        final accent = name == 'light'
            ? scheme.primary
            : scheme.primaryFixedDim;

        expect(
          style.overlayColor!.resolve({WidgetState.pressed}),
          scheme.onSurface.withValues(alpha: dimens.opacityPressed),
        );
        expect(
          style.overlayColor!.resolve({
            WidgetState.selected,
            WidgetState.hovered,
          }),
          accent.withValues(alpha: dimens.opacityHover),
        );
        expect(style.overlayColor!.resolve({WidgetState.disabled}), isNull);
        final resting = style.shape!.resolve({}) as MxFocusRingBorder;
        final focused =
            style.shape!.resolve({WidgetState.focused}) as MxFocusRingBorder;
        expect(resting.base, isA<StadiumBorder>());
        expect(resting.ring, BorderSide.none);
        expect(focused.ring.color, scheme.primary);
        expect(focused.ring.width, dimens.strokeFocus);
        expect(focused.gap, dimens.strokeFocusGap);
      });

      testWidgets(
        'raw buttons are full-radius and at least the button height',
        (tester) async {
          await pump(
            tester,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(onPressed: () {}, child: const Text('Filled')),
                OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                TextButton(onPressed: () {}, child: const Text('Text')),
              ],
            ),
          );
          for (final label in ['Filled', 'Outlined', 'Text']) {
            final box = find.ancestor(
              of: find.text(label),
              matching: find.byType(Material),
            );
            final material = tester.widget<Material>(box.first);
            expect(
              tester.getSize(box.first).height,
              greaterThanOrEqualTo(dimens.sizeButton),
              reason: label,
            );
            expect(
              (material.shape! as MxFocusRingBorder).base,
              isA<StadiumBorder>(),
              reason: label,
            );
          }
        },
      );

      testWidgets('a raw IconButton is the control size, round', (
        tester,
      ) async {
        await pump(
          tester,
          IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
        );
        expect(
          tester.getSize(find.byType(IconButton)),
          Size.square(dimens.sizeControl),
        );
      });

      testWidgets('a framework dialog takes the surface, radius and scrim', (
        tester,
      ) async {
        await pump(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(title: Text('Title')),
              ),
              child: const Text('open'),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final surface = tester.widget<Material>(
          find
              .ancestor(of: find.text('Title'), matching: find.byType(Material))
              .first,
        );
        expect(surface.color, scheme.surfaceContainerHigh);
        expect(
          (surface.shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(dimens.radiusXl),
        );
        final barrier = tester.widget<ModalBarrier>(
          find.byType(ModalBarrier).last,
        );
        expect(
          barrier.color,
          scheme.scrim.withValues(alpha: dimens.opacityScrim),
        );
      });
    });
  }
}
