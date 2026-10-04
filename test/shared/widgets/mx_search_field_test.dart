import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('typing shows a named clear button that empties the field', (
    tester,
  ) async {
    final controller = TextEditingController();
    final List<String> seen = [];
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxSearchField(
          hint: 'Search decks',
          controller: controller,
          clearLabel: 'Clear search',
          onChanged: seen.add,
        ),
      ),
    );
    expect(find.byTooltip('Clear search'), findsNothing);
    await tester.enterText(find.byType(TextField), 'kor');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(seen.last, '');
  });

  testWidgets('trigger mode opens search on a tap and reads as a button', (
    tester,
  ) async {
    var opened = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxSearchField(hint: 'Search decks', onOpen: () => opened++),
      ),
    );
    expect(find.byType(TextField), findsNothing);
    expect(
      tester.getSize(find.byType(MxSearchField)).height,
      greaterThanOrEqualTo(AppSize.field),
    );
    await tester.tap(find.text('Search decks'));
    expect(opened, 1);
    expect(
      tester.getSemantics(find.byType(MxSearchField)),
      matchesSemantics(
        label: 'Search decks',
        isButton: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('the trigger starts its hint where the input starts its text', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MxSearchField(
              hint: 'Typed',
              controller: TextEditingController(text: 'Typed'),
            ),
            MxSearchField(hint: 'Trigger', onOpen: () {}),
          ],
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Trigger')).dx,
      moreOrLessEquals(
        tester.getTopLeft(find.text('Typed').last).dx,
        epsilon: 0.5,
      ),
    );
  });
}
