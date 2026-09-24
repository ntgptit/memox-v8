import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
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
      BorderSide(
        color: MxDerivedColors.resolve(
          scheme,
          MxSemanticColors.light,
        ).ghostBorder,
      ),
    );
  });

  testWidgets('the caption sits under the action, centred at 0.7', (
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
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('12 cards selected'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.7,
    );
    expect(
      tester.widget<Text>(find.text('12 cards selected')).textAlign,
      TextAlign.center,
    );
  });
}
