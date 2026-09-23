import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';

import '../../support/widget_harness.dart';

List<Widget> _rows(int count) => [
  for (var i = 0; i < count; i++) SizedBox(key: ValueKey('row-$i'), height: 48),
];

Widget _width(Widget child) => SizedBox(width: 360, child: child);

void main() {
  testWidgets('an overline over a full-bleed card, and 16 below', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(MxSection(title: 'Reminders', children: _rows(1))),
    );

    expect(find.byType(MxListSectionHeader), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row-0'))),
      tester.getTopLeft(find.byType(MxCard)),
    );
    expect(
      tester.getBottomLeft(find.byType(MxSection)).dy -
          tester.getBottomLeft(find.byType(MxCard)).dy,
      16,
    );
  });

  testWidgets('untitled: the card only, still 16 below', (tester) async {
    await pumpMx(tester, _width(MxSection(children: _rows(1))));

    expect(find.byType(MxListSectionHeader), findsNothing);
    expect(
      tester.getTopLeft(find.byType(MxCard)),
      tester.getTopLeft(find.byType(MxSection)),
    );
    expect(
      tester.getBottomLeft(find.byType(MxSection)).dy -
          tester.getBottomLeft(find.byType(MxCard)).dy,
      16,
    );
  });

  testWidgets('ghost dividers between rows, none after the last', (
    tester,
  ) async {
    final ghost = MxDerivedColors.resolve(
      AppColorSchemes.light,
      MxSemanticColors.light,
    ).ghostBorder;
    await pumpMx(tester, _width(MxSection(children: _rows(3))));
    final dividers = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(MxCard),
            matching: find.byType(ColoredBox),
          ),
        )
        .where((box) => box.color == ghost);

    expect(dividers, hasLength(2));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row-1'))).dy -
          tester.getBottomLeft(find.byKey(const ValueKey('row-0'))).dy,
      1,
    );
  });

  testWidgets('a note sits 8 below the card, inset 4', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxSection(
          note: 'Changes apply to future sessions.',
          children: _rows(1),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byType(MxNote)) -
          tester.getBottomLeft(find.byType(MxCard)),
      const Offset(4, 8),
    );
  });
}
