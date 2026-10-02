import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../support/widget_harness.dart';
import 'expect_one_primary.dart';

void main() {
  testWidgets('one primary passes; an outline beside it does not count', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Column(
        children: [
          MxButton(label: 'Continue', onPressed: () {}),
          MxButton(
            label: 'Start new',
            tone: MxButtonTone.outline,
            onPressed: () {},
          ),
        ],
      ),
    );
    expectOnePrimaryPerDecision(tester);
  });

  testWidgets('a primary and a FAB fail', (tester) async {
    await pumpMx(
      tester,
      Column(
        children: [
          MxButton(label: 'New card', onPressed: () {}),
          MxFab(icon: AppIcons.add, semanticLabel: 'New', onPressed: () {}),
        ],
      ),
    );
    expect(
      () => expectOnePrimaryPerDecision(tester),
      throwsA(isA<TestFailure>()),
    );
  });

  testWidgets('no primary where one is due fails', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Edit', tone: MxButtonTone.outline, onPressed: () {}),
    );
    expect(
      () => expectOnePrimaryPerDecision(tester),
      throwsA(isA<TestFailure>()),
    );
    expectOnePrimaryPerDecision(tester, expected: 0);
  });

  testWidgets('a primary where none is due fails under expected: 0', (
    tester,
  ) async {
    await pumpMx(tester, MxButton(label: 'Save', onPressed: () {}));
    expect(
      () => expectOnePrimaryPerDecision(tester, expected: 0),
      throwsA(isA<TestFailure>()),
    );
  });
}
