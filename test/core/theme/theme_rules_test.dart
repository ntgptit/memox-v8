import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

Future<BuildContext> contextOf(WidgetTester tester, ThemeData theme) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets(
    'light: accent and its on-colour are primary and onPrimary, deck icon is info',
    (tester) async {
      final context = await contextOf(tester, buildLightTheme());
      expect(context.accentColor, Theme.of(context).colorScheme.primary);
      expect(context.onAccentColor, Theme.of(context).colorScheme.onPrimary);
      expect(context.deckIconColor, context.mxColors.info);
    },
  );

  testWidgets(
    'dark: accent and its on-colour are the fixed steps, deck icon is infoContainer',
    (tester) async {
      final context = await contextOf(tester, buildDarkTheme());
      expect(
        context.accentColor,
        Theme.of(context).colorScheme.primaryFixedDim,
      );
      expect(
        context.onAccentColor,
        Theme.of(context).colorScheme.onPrimaryFixed,
      );
      expect(context.deckIconColor, context.mxColors.infoContainer);
    },
  );

  testWidgets('screen margin follows the window width', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(599, 800);
    var context = await contextOf(tester, buildLightTheme());
    expect(context.screenMargin, context.dimens.marginScreen);
    expect(context.windowSize, WindowSize.compact);

    tester.view.physicalSize = const Size(600, 800);
    context = await contextOf(tester, buildLightTheme());
    expect(context.screenMargin, context.dimens.marginScreenMedium);
    expect(context.windowSize, WindowSize.medium);

    tester.view.physicalSize = const Size(840, 800);
    context = await contextOf(tester, buildLightTheme());
    expect(context.windowSize, WindowSize.expanded);
  });
}
