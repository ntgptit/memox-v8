import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
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
