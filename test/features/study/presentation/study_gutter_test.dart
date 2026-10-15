import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/features/study/presentation/widgets/support/recall_countdown_bar_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/session_context_line_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_cta_row_widget.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';

// M3F-19: the study session's own bodies sit on the screen margin: 16 on a
// compact window, 24 from 600 dp, as the bar, the hint and the answer bodies
// around them do.

EdgeInsets _gutter(WidgetTester tester, Type widget) => tester
    .widget<Padding>(
      find
          .descendant(of: find.byType(widget), matching: find.byType(Padding))
          .first,
    )
    .padding
    .resolve(TextDirection.ltr);

void main() {
  final bodies = <(String, Type, Widget)>[
    (
      'the context line',
      SessionContextLineWidget,
      const SessionContextLineWidget(text: 'Korean', shown: 'KOREAN'),
    ),
    (
      'the action row',
      StudyCtaRowWidget,
      const StudyCtaRowWidget(
        children: [MxButton(label: 'Next', isBlock: true, onPressed: null)],
      ),
    ),
    (
      'the recall clock',
      RecallCountdownBarWidget,
      const RecallCountdownBarWidget(
        caption: 'Time to recall',
        remainingMs: 10000,
        isTimedOut: false,
      ),
    ),
  ];
  for (final (name, type, widget) in bodies) {
    for (final (width, margin) in [(360.0, 16.0), (700.0, 24.0)]) {
      libraryTest('$name keeps the $margin screen margin at ${width.toInt()} '
          'wide', (tester, env) async {
        await pumpLibraryScreen(
          tester,
          env,
          WindowWidthScope(
            width: width,
            child: Scaffold(body: SizedBox(width: 360, child: widget)),
          ),
        );

        final gutter = _gutter(tester, type);
        expect((gutter.left, gutter.right), (margin, margin));
      });
    }
  }
}
