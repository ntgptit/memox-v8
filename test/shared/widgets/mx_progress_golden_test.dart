@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: children,
  ),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('linear_progress', 'tones'): () => _column([
      for (final (index, tone) in MxLinearProgressTone.values.indexed)
        MxLinearProgress(
          value: 0.2 + index * 0.1,
          semanticLabel: tone.name,
          tone: tone,
          size: index.isEven
              ? MxLinearProgressSize.regular
              : MxLinearProgressSize.thick,
        ),
    ]),
    ('skeleton', 'list'): () => const SizedBox(
      width: 380,
      child: MxSkeletonList(semanticLabel: 'Loading decks'),
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
