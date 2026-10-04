@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('stepper', 'states'): () => _column([
      MxStepper(
        value: 20,
        min: 1,
        max: 200,
        onChanged: (_) {},
        decreaseLabel: 'Fewer',
        increaseLabel: 'More',
      ),
      MxStepper(
        value: 1,
        min: 1,
        max: 200,
        onChanged: (_) {},
        decreaseLabel: 'Fewer',
        increaseLabel: 'More',
      ),
      MxStepper(
        value: 7,
        min: 0,
        max: 23,
        minDigits: 2,
        onChanged: (_) {},
        decreaseLabel: 'Earlier',
        increaseLabel: 'Later',
      ),
    ]),
    ('segmented_tray', 'states'): () => _column([
      Align(
        alignment: Alignment.centerLeft,
        child: MxSegmentedTray<int>(
          segments: const [
            MxSegmentedTrayItem(value: 0, label: 'Server'),
            MxSegmentedTrayItem(value: 1, label: 'Not sent (3)'),
          ],
          selected: 0,
          onChanged: (_) {},
        ),
      ),
      MxSegmentedTray<int>(
        segments: const [
          MxSegmentedTrayItem(value: 7, label: 'Last 7 days'),
          MxSegmentedTrayItem(value: 30, label: 'Last 30 days'),
        ],
        selected: 30,
        isExpanded: true,
        onChanged: (_) {},
      ),
    ]),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
