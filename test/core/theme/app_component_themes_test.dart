import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';

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

      test(
        'fields: filled, outline at rest, primary focus ring, no label gap',
        () {
          final fields = theme.inputDecorationTheme;
          expect(fields.filled, isTrue);
          expect(
            WidgetStateProperty.resolveAs(fields.fillColor!, <WidgetState>{}),
            scheme.surfaceContainerLow,
          );
          expect(
            WidgetStateProperty.resolveAs(fields.fillColor!, {
              WidgetState.focused,
            }),
            scheme.surfaceContainerLowest,
          );
          final edge = fields.enabledBorder! as OutlineInputBorder;
          expect(edge.borderSide.color, scheme.outline);
          expect(edge.gapPadding, 0);
          expect(edge.borderRadius, BorderRadius.circular(dimens.radiusMd));
          final focused = fields.focusedBorder! as OutlineInputBorder;
          expect(focused.borderSide.color, scheme.primary);
          expect(focused.borderSide.width, dimens.strokeFocus);
          expect(
            (fields.errorBorder! as OutlineInputBorder).borderSide.color,
            scheme.error,
          );
          expect(fields.hintStyle!.color, scheme.onSurfaceVariant);
        },
      );

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

      test('progress: a track tall, success fill on the highest container', () {
        final progress = theme.progressIndicatorTheme;
        expect(progress.linearMinHeight, dimens.sizeTrack);
        expect(progress.color, mx.successContainer);
        expect(progress.linearTrackColor, scheme.surfaceContainerHighest);
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
        expect(chip.iconTheme!.color, scheme.primary);
        expect(chip.iconTheme!.size, dimens.sizeIconButton);
        expect(chip.padding, EdgeInsets.all(dimens.space8));
        expect(
          chip.labelPadding,
          EdgeInsets.symmetric(horizontal: dimens.space8),
        );
      });

      test('dialog, sheet and snack bar carry their tokens', () {
        expect(theme.dialogTheme.backgroundColor, scheme.surfaceContainerHigh);
        expect(
          (theme.dialogTheme.shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(dimens.radiusXl),
        );
        expect(
          theme.dialogTheme.barrierColor,
          scheme.scrim.withValues(alpha: dimens.opacityScrim),
        );
        expect(
          (theme.bottomSheetTheme.shape! as RoundedRectangleBorder)
              .borderRadius,
          BorderRadius.vertical(top: Radius.circular(dimens.radiusXl)),
        );
        expect(theme.snackBarTheme.backgroundColor, scheme.inverseSurface);
        expect(theme.snackBarTheme.actionTextColor, scheme.inversePrimary);
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
