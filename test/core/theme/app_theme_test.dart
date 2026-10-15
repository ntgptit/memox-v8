import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/core/theme/generated/text_theme.g.dart';
import 'package:memox/core/theme/theme_context.dart';

void main() {
  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    group(name, () {
      test('is Material 3 and inks its text onSurface', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.textTheme.bodyMedium!.color, theme.colorScheme.onSurface);
      });

      // CircleAvatar, FlexibleSpaceBar and UserAccountsDrawerHeader read
      // primaryTextTheme directly, not textTheme.
      test('primaryTextTheme is bound to the theme family too', () {
        final style = theme.primaryTextTheme.bodyMedium!;
        final weight = style.fontWeight ?? FontWeight.w400;

        expect(style.fontFamily, kFontFamily);
        expect(
          style.fontVariations,
          contains(FontVariation.weight(weight.value.toDouble())),
        );
      });

      // SW-REV-007: the slots Material paints through when no component
      // theme says otherwise; left at their defaults they drew grey ripples,
      // a raised snackbar and a grey tooltip in both themes.
      test('rows press in onSurface at the pressed overlay', () {
        final scheme = theme.colorScheme;
        final pressed = scheme.onSurface.withValues(
          alpha: theme.extension<AppDimens>()!.opacityPressed,
        );

        expect(theme.splashColor, pressed);
        expect(theme.highlightColor, pressed);
      });

      // M3F-12: an Icon with no IconTheme ancestor read the SDK's black 87%
      // or white; a supporting glyph is onSurfaceVariant (owner 2026-10-15).
      test('M3F-12: the ambient icon is onSurfaceVariant at sizeIcon', () {
        expect(theme.iconTheme.color, theme.colorScheme.onSurfaceVariant);
        expect(theme.iconTheme.size, theme.extension<AppDimens>()!.sizeIcon);
      });

      // M3F-13: hover and focus fell to the SDK's black or white at 4% and
      // 12%; the buttons already use the token layers.
      test('M3F-13: rows hover at opacityHover and focus at opacityFocus', () {
        final scheme = theme.colorScheme;
        final dimens = theme.extension<AppDimens>()!;

        expect(
          theme.hoverColor,
          scheme.onSurface.withValues(alpha: dimens.opacityHover),
        );
        expect(
          theme.focusColor,
          scheme.onSurface.withValues(alpha: dimens.opacityFocus),
        );
      });

      // M3F-14: density and tap size were the platform's, so Linux, Windows
      // and macOS (the Web review lane) rendered compact.
      test('M3F-14: standard density and a padded tap target', () {
        expect(theme.visualDensity, VisualDensity.standard);
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      });

      test('snackbar is flat: the inverse surface carries it', () {
        expect(theme.snackBarTheme.elevation, 0);
      });

      test('tooltip: the caption on the inverse surface, radiusXs', () {
        final scheme = theme.colorScheme;
        final dimens = theme.extension<AppDimens>()!;

        expect(
          theme.tooltipTheme.decoration,
          BoxDecoration(
            color: scheme.inverseSurface,
            borderRadius: BorderRadius.circular(dimens.radiusXs),
          ),
        );
        expect(theme.tooltipTheme.textStyle!.color, scheme.onInverseSurface);
        expect(
          theme.tooltipTheme.textStyle!.fontSize,
          theme.textTheme.bodySmall!.fontSize,
        );
      });
    });
  }

  test('light to dark lerp keeps the extension (theme animation)', () {
    final mid = ThemeData.lerp(buildLightTheme(), buildDarkTheme(), 0.5);

    expect(
      mid.extension<MxColorsExtension>()!.successContainer,
      Color.lerp(
        MxColorsExtension.light.successContainer,
        MxColorsExtension.dark.successContainer,
        0.5,
      ),
    );
  });

  testWidgets('a theme without the extension fails with the fix named', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      () => context.mxColors,
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('buildLightTheme'),
        ),
      ),
    );
  });
}
