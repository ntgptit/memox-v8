import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('8 / 16 / 16 + inset padding around a block action', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: MxFooterBar(
            child: MxButton(label: 'Save', isBlock: true, onPressed: () {}),
          ),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 20),
    );
    final bar = tester.getRect(find.byType(MxFooterBar));
    final button = tester.getRect(find.byType(MxButton));

    expect(button.left - bar.left, 16);
    expect(bar.right - button.right, 16);
    expect(button.top - bar.top, 8);
    expect(bar.bottom - button.bottom, 16 + 20);
  });

  testWidgets('surface fill with a 1px ghost top border', (tester) async {
    await pumpMx(tester, const MxFooterBar(child: SizedBox(height: 48)));
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(MxFooterBar),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;

    expect(decoration.color, scheme.surface);
    expect(
      (decoration.border! as Border).top,
      BorderSide(color: MxSemanticColors.light.border),
    );
  });

  testWidgets('the caption sits under the action, centred at full strength', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFooterBar(
        caption: '12 cards selected',
        child: MxButton(label: 'Move', isBlock: true, onPressed: () {}),
      ),
    );

    expect(
      tester.getTopLeft(find.text('12 cards selected')).dy,
      greaterThan(tester.getBottomLeft(find.byType(MxButton)).dy),
    );
    expect(
      find.descendant(
        of: find.byType(MxFooterBar),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(
      tester.widget<Text>(find.text('12 cards selected')).textAlign,
      TextAlign.center,
    );
  });
  testWidgets('the caption steps aside while the keyboard is up', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
        child: MxFooterBar(
          caption: 'Front and back are required to save.',
          child: MxButton(label: 'Save', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('Front and back are required to save.'), findsNothing);
    expect(find.text('Save'), findsOneWidget);
  });
  testWidgets('the caption steps aside in a real shell, whose Scaffold '
      'strips the keyboard inset from its body', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await pumpMxPage(
      tester,
      MxAppShell(
        body: const SizedBox.expand(),
        footer: MxFooterBar(
          caption: 'Front and back are required to save.',
          child: MxButton(label: 'Save', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('Front and back are required to save.'), findsNothing);
    expect(find.text('Save'), findsOneWidget);
  });
  testWidgets('the caption steps aside in a shell nested in a tab shell', (
    tester,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await pumpMxPage(
      tester,
      MxAppShell(
        body: MxAppShell(
          body: const SizedBox.expand(),
          footer: MxFooterBar(
            caption: 'Front and back are required to save.',
            child: MxButton(label: 'Save', onPressed: () {}),
          ),
        ),
        bottomBar: const SizedBox(height: 80),
      ),
    );

    expect(find.text('Front and back are required to save.'), findsNothing);
  });
}
