import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _chip = find.byType(FButton);

/// The ForUI ghost extra-small button style the trigger is built on.
FButtonStyle _style(WidgetTester tester) =>
    forUiTheme(tester, _chip).buttonStyles.ghost.xs;

void main() {
  testWidgets('ghost: no fill, the ghost label colour, a trailing chevron', (
    tester,
  ) async {
    await pumpMx(tester, MxChipTrigger(label: 'Sort: Due', onPressed: () {}));
    final style = _style(tester);

    expect(paintedRect(tester, _chip).height, 32);
    expect(paintedDecoration(tester, _chip).color, isNull);
    expect(
      textColor(tester, find.text('Sort: Due')),
      style.contentStyle.textStyle.resolve({}).color,
    );
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);
    expect(
      tester.getSize(find.byIcon(AppIcons.chevronDown)).width,
      style.contentStyle.iconStyle.resolve({}).size,
    );
  });

  testWidgets('chip geometry: the label inset by the style padding, no edge', (
    tester,
  ) async {
    await pumpMx(tester, MxChipTrigger(label: 'Sort: Due', onPressed: () {}));
    final padding = _style(tester).contentStyle.padding
        .resolve(TextDirection.ltr);

    expect(paintedSide(tester, _chip), BorderSide.none);
    expect(
      tester.getTopLeft(find.text('Sort: Due')).dx -
          paintedRect(tester, _chip).left,
      closeTo(padding.left, 0.01),
    );
  });

  testWidgets('opens its menu on tap and meets the 48 target', (tester) async {
    var taps = 0;
    await pumpMx(tester, MxChipTrigger(label: 'Sort', onPressed: () => taps++));
    await tester.tap(find.byType(MxChipTrigger));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(tester.getSize(_chip).height, greaterThanOrEqualTo(48));
    await expectAccessibleTargets(tester);
  });

  // SW-REV-010: Import's sheet chip carries a workbook sheet name, user
  // data; a label wider than the column ends in an ellipsis, never an
  // overflow.
  testWidgets('a label wider than its column ends in an ellipsis', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 200,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MxChipTrigger(
            label: 'Sheet: Vocabulary_Korean_Lesson_12_Final (3 of 5)',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<Text>(
            find.text('Sheet: Vocabulary_Korean_Lesson_12_Final (3 of 5)'),
          )
          .overflow,
      TextOverflow.ellipsis,
    );
  });

  // TalkBack reads one node naming the trigger's purpose and its value, not
  // the bare value and "button" (DEV-394).
  testWidgets('semanticLabel is the one node TalkBack reads; the painted '
      'label is unchanged', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxChipTrigger(
        label: '1×',
        semanticLabel: 'Playback speed, 1×',
        onPressed: () => taps++,
      ),
    );

    expect(find.text('1×'), findsOneWidget);
    expect(find.bySemanticsLabel('1×'), findsNothing);
    final node = tester.getSemantics(
      find.bySemanticsLabel('Playback speed, 1×'),
    );
    expect(
      node,
      isSemantics(
        label: 'Playback speed, 1×',
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
      ),
    );
    await tester.tap(find.byType(MxChipTrigger));
    await tester.pumpAndSettle();
    expect(taps, 1);

    await pumpMx(
      tester,
      const MxChipTrigger(
        label: '1×',
        semanticLabel: 'Playback speed, 1×',
        onPressed: null,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Playback speed, 1×')),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('without semanticLabel the visible label stays the name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, MxChipTrigger(label: 'Sort: Due', onPressed: () {}));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Sort: Due')),
      isSemantics(
        label: 'Sort: Due',
        isButton: true,
        hasTapAction: true,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });
}
