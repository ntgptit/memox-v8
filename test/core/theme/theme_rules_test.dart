import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

import '../../support/theme_harness.dart';

void main() {
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

  testWidgets(
    'a width scope sets the size class, whatever the MediaQuery says',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(540, 800);
      late BuildContext inside;
      await tester.pumpWidget(
        MaterialApp(
          theme: materialHostTheme(buildLightTheme()),
          builder: mxThemeBuilder(buildLightTheme()),
          home: WindowWidthScope(
            width: 620,
            child: Builder(
              builder: (context) {
                inside = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(inside.windowSize, WindowSize.medium);
      expect(inside.screenMargin, inside.dimens.marginScreenMedium);
    },
  );
}
