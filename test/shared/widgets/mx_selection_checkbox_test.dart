import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../support/palette_status.dart';
import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _checkbox = find.byType(MxSelectionCheckbox);

ShapeDecoration _box(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: _checkbox,
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as ShapeDecoration;

FCheckboxStyle _style(WidgetTester tester) =>
    forUiTheme(tester, _checkbox).checkboxStyle;

void main() {
  // ForUI's checkbox, painted only: the row around it is the tap target.
  testWidgets('unchecked: the style size, the card ground, a muted edge', (
    tester,
  ) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: false));
    final style = _style(tester);

    expect(
      tester.getSize(
        find.descendant(of: _checkbox, matching: find.byType(DecoratedBox)),
      ),
      Size.square(style.size),
    );
    expect(_box(tester), style.decoration.resolve(<FVariant>{}));
    expect(_box(tester).color, appLightColors.card);
    expect(
      (_box(tester).shape as OutlinedBorder).side.color,
      appLightColors.mutedForeground,
    );
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('checked: the primary fill, the primary-foreground check, no '
      'edge', (tester) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: true));
    await tester.pumpAndSettle();
    final style = _style(tester);
    final checked = <FVariant>{FCheckboxVariant.selected};

    expect(_box(tester), style.decoration.resolve(checked));
    expect(_box(tester).color, lightStatus.primaryInk);
    expect((_box(tester).shape as OutlinedBorder).side, BorderSide.none);
    expect(
      iconColor(tester, find.byType(Icon)),
      appLightColors.primaryForeground,
    );
    expect(
      tester.getSize(find.byType(Icon)).width,
      lessThanOrEqualTo(style.size),
    );
  });

  // In dark the tick is the brand's ink, which reads on a sheet, and the
  // check mark is the navy page, which reads on the pale ink.
  testWidgets('dark checked: the brand ink fill and the page-coloured check', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxSelectionCheckbox(isChecked: true),
      brightness: Brightness.dark,
    );
    await tester.pumpAndSettle();

    expect(_box(tester).color, darkStatus.primaryInk);
    expect(iconColor(tester, find.byType(Icon)), appDarkColors.background);
  });

  testWidgets('it is painted only: out of the semantics tree and out of '
      'reach of a pointer', (tester) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: true));

    expect(
      find.descendant(of: _checkbox, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
    final ignoring = tester.widget<IgnorePointer>(
      find
          .descendant(of: _checkbox, matching: find.byType(IgnorePointer))
          .first,
    );
    expect(ignoring.ignoring, isTrue);
  });

  testWidgets('it takes no focus of its own: the row is the one tab stop', (
    tester,
  ) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: false));
    useKeyboardFocusHighlight();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final focused = FocusManager.instance.primaryFocus?.context;
    final inside =
        focused != null &&
        find
            .descendant(
              of: _checkbox,
              matching: find.byElementPredicate((e) => e == focused),
            )
            .evaluate()
            .isNotEmpty;
    expect(inside, isFalse);
  });
}
