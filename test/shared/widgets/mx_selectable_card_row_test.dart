import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_selectable_card_row.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../support/widget_harness.dart';

Widget _row({
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  bool isSelecting = false,
  bool isSelected = false,
  bool isEnabled = true,
  Widget? trailing,
  String? semanticLabel,
}) => SizedBox(
  width: 360,
  child: MxSelectableCardRow(
    onTap: onTap,
    onLongPress: onLongPress,
    isSelecting: isSelecting,
    isSelected: isSelected,
    isEnabled: isEnabled,
    trailing: trailing,
    semanticLabel: semanticLabel,
    child: const Text('Korean'),
  ),
);

void main() {
  testWidgets('a tap opens and a long-press selects; the content sits 16 in '
      'and 12 down (M3-D1)', (tester) async {
    var taps = 0;
    var holds = 0;
    await pumpMx(tester, _row(onTap: () => taps++, onLongPress: () => holds++));
    await tester.tap(find.text('Korean'));
    await tester.longPress(find.text('Korean'));

    expect((taps, holds), (1, 1));
    final card = tester.getTopLeft(find.byType(MxCard));
    final text = tester.getTopLeft(find.text('Korean'));
    expect(text.dx - card.dx, 16);
    expect(text.dy - card.dy, 12);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  testWidgets('selecting shows the checkbox, ticked when selected, centred '
      'on the card with the trailing control', (tester) async {
    await pumpMx(
      tester,
      _row(
        onTap: () {},
        isSelecting: true,
        isSelected: true,
        trailing: MxIconButton(
          icon: AppIcons.more,
          semanticLabel: 'More',
          onPressed: () {},
        ),
      ),
    );

    expect(
      tester
          .widget<MxSelectionCheckbox>(find.byType(MxSelectionCheckbox))
          .isChecked,
      isTrue,
    );
    expect(tester.widget<MxCard>(find.byType(MxCard)).isSelected, isTrue);
    expectCentredOn(tester, find.byType(MxCard), [
      find.byType(MxSelectionCheckbox),
      find.byType(MxIconButton),
    ]);
  });

  testWidgets('with a label, one node carries the label, the checked state, '
      'the tap and the long-press; the trailing control stays its own', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var more = 0;
    await pumpMx(
      tester,
      _row(
        onTap: () {},
        onLongPress: () {},
        isSelecting: true,
        semanticLabel: 'Korean, 6 cards',
        trailing: MxIconButton(
          icon: AppIcons.more,
          semanticLabel: 'More',
          onPressed: () => more++,
        ),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Korean, 6 cards')),
      isSemantics(
        label: 'Korean, 6 cards',
        isChecked: false,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );
    expect(find.text('Korean'), findsOneWidget);
    await tester.tap(find.byTooltip('More'));
    expect(more, 1);
    handle.dispose();
  });

  testWidgets('without a label, the content is read with the checked state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      _row(onTap: () {}, isSelecting: true, isSelected: true),
    );

    expect(
      tester.getSemantics(find.text('Korean')),
      isSemantics(label: 'Korean', isChecked: true),
    );
    handle.dispose();
  });

  testWidgets('disabled: dimmed to 0.38, no tap, no long-press', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      _row(onTap: () => taps++, isSelecting: true, isEnabled: false),
    );
    await tester.tap(find.text('Korean'), warnIfMissed: false);

    expect(taps, 0);
    expect(
      tester.widget<Opacity>(find.byType(Opacity).first).opacity,
      closeTo(0.38, 0.001),
    );
  });

  testWidgets('tappable row and trailing control are 48 targets with names', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _row(
        onTap: () {},
        semanticLabel: 'Korean',
        trailing: MxIconButton(
          icon: AppIcons.more,
          semanticLabel: 'More',
          onPressed: () {},
        ),
      ),
    );
    await expectAccessibleTargets(tester);
  });
}
