import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';

void main() {
  group('buildLightTheme / buildDarkTheme', () {
    final themes = {
      'light': (
        buildLightTheme(),
        AppColorSchemes.light,
        MxSemanticColors.light,
      ),
      'dark': (buildDarkTheme(), AppColorSchemes.dark, MxSemanticColors.dark),
    };

    for (final MapEntry(key: name, value: (theme, scheme, semantic))
        in themes.entries) {
      test('$name carries its scheme, extension and page ground', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme, scheme);
        expect(theme.extension<MxSemanticColors>(), semantic);
        expect(theme.scaffoldBackgroundColor, scheme.surface);
      });

      test('$name binds the V3 type scale in the theme family', () {
        expect(theme.textTheme.displayMedium!.fontSize, 40);
        expect(theme.textTheme.bodySmall!.fontFamily, AppTypography.fontFamily);
      });

      // CircleAvatar, FlexibleSpaceBar and UserAccountsDrawerHeader read
      // primaryTextTheme directly, not textTheme.
      test('$name primaryTextTheme is bound to the theme family too', () {
        final style = theme.primaryTextTheme.bodyMedium!;
        final weight = style.fontWeight ?? FontWeight.w400;

        expect(style.fontFamily, AppTypography.fontFamily);
        expect(style.fontSize, 14);
        expect(
          style.fontVariations,
          contains(FontVariation.weight(weight.value.toDouble())),
        );
      });

      test('$name text ink is onSurface', () {
        expect(theme.textTheme.bodyMedium!.color, scheme.onSurface);
      });
    }
  });

  test('light to dark lerp keeps the extension (theme animation)', () {
    final mid = ThemeData.lerp(buildLightTheme(), buildDarkTheme(), 0.5);

    expect(
      mid.extension<MxSemanticColors>()!.mastery,
      Color.lerp(
        MxSemanticColors.light.mastery,
        MxSemanticColors.dark.mastery,
        0.5,
      ),
    );
  });

  group('ThemeContext', () {
    Future<BuildContext> pumpUnder(WidgetTester tester, ThemeData theme) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return captured;
    }

    testWidgets('reads the scheme, text theme and MemoX colours', (
      tester,
    ) async {
      final context = await pumpUnder(tester, buildDarkTheme());

      expect(context.colors, AppColorSchemes.dark);
      expect(context.texts.displayMedium!.fontSize, 40);
      expect(context.semanticColors, MxSemanticColors.dark);
      expect(
        context.derivedColors.surfaceHero,
        MxDerivedColors.resolve(
          AppColorSchemes.dark,
          MxSemanticColors.dark,
        ).surfaceHero,
      );
    });

    testWidgets('a theme without the extension fails with the fix named', (
      tester,
    ) async {
      final context = await pumpUnder(tester, ThemeData());

      expect(
        () => context.semanticColors,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('buildLightTheme'),
          ),
        ),
      );
    });
  });
}
