@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import 'support/mx_harness.dart';

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('spinner', 'sizes'): () => Wrap(
      spacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final size in MxSpinnerSize.values)
          MxSpinner(semanticLabel: 'Loading', size: size),
      ],
    ),
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
