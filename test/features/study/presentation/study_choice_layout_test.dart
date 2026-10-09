import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_choice_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';

// DEV-359: Match and Guess pad their choices by StudyChoiceWidget.ringRoom
// (4 dp above and below) so the outside focus ring fits the viewport. The
// inset is accepted only if no layout degrades on a short phone or at text
// scale 1.3: no overflow, every choice reachable and whole, the footer clear.

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

/// The phone and text scale a mode is checked at.
const _cases = [
  (size: Size(360, 640), scale: 1.0),
  (size: Size(360, 800), scale: 1.3),
  (size: Size(360, 640), scale: 1.3),
];

void _expectWithin(Rect inner, Rect outer, String what) {
  expect(inner.top, greaterThanOrEqualTo(outer.top - 0.01), reason: what);
  expect(inner.bottom, lessThanOrEqualTo(outer.bottom + 0.01), reason: what);
  expect(inner.left, greaterThanOrEqualTo(outer.left - 0.01), reason: what);
  expect(inner.right, lessThanOrEqualTo(outer.right + 0.01), reason: what);
}

void main() {
  for (final mode in [StudyMode.match, StudyMode.guess]) {
    for (final c in _cases) {
      final name =
          '${mode.name} on ${c.size.width.toInt()}x${c.size.height.toInt()} '
          'at text scale ${c.scale}';
      libraryTest('$name: every choice is whole and reachable, the footer '
          'is clear', (tester, env) async {
        final id = await openFiveDueReview(
          env.db,
          env.decks,
          libraryToday,
          mode,
        );
        await pumpLibraryScreen(tester, env, _screen(id), textScale: c.scale);
        tester.view.physicalSize = c.size;
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);

        final scrollable = find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first;
        final position = tester.state<ScrollableState>(scrollable).position;
        final viewport = tester.getRect(find.byType(CustomScrollView).first);
        final footer = tester.getRect(find.byType(SessionFooterHintWidget));
        final choices = find.byType(StudyChoiceWidget);
        final count = choices.evaluate().length;
        expect(count, mode == StudyMode.match ? 10 : 5);

        // The least height the content needs; the scroll area fills the
        // viewport when that is smaller, and scrolls when it is larger.
        final padded = tester.renderObject<RenderBox>(
          find
              .descendant(
                of: find.byType(SliverFillRemaining),
                matching: find.byType(Padding),
              )
              .first,
        );
        final needed = padded.getMinIntrinsicHeight(viewport.width);
        final smallest = [
          for (var i = 0; i < count; i++) tester.getSize(choices.at(i)).height,
        ].reduce(math.min);
        printOnFailure(
          'MEASURED $name: content needs ${needed.toStringAsFixed(1)} dp of '
          '${position.viewportDimension.toStringAsFixed(1)} dp viewport, '
          'scrolls ${position.maxScrollExtent > 0.01 ? 'yes, by '
                    '${position.maxScrollExtent.toStringAsFixed(1)} dp' : 'no'}'
          ', smallest choice ${smallest.toStringAsFixed(1)} dp, footer '
          '${footer.top.toStringAsFixed(1)}..${footer.bottom.toStringAsFixed(1)}'
          ' of ${c.size.height.toInt()}',
        );
        // A choice stays a tap target.
        expect(smallest, greaterThanOrEqualTo(48));

        // The footer sits under the scroll area, on the screen, and nothing
        // of the scroll area is painted over it.
        expect(footer.top, greaterThanOrEqualTo(viewport.bottom - 0.01));
        expect(footer.bottom, lessThanOrEqualTo(c.size.height + 0.01));
        expect(footer.height, greaterThan(0));

        Rect ringed(int index) => tester
            .getRect(choices.at(index))
            .inflate(StudyChoiceWidget.ringRoom);

        if (position.maxScrollExtent <= 0.01) {
          // Nothing scrolls: every choice, ring included, is on screen.
          for (var i = 0; i < count; i++) {
            _expectWithin(ringed(i), viewport, 'choice $i');
          }
          return;
        }
        // The list scrolls: each end reaches its viewport edge whole.
        position.jumpTo(position.minScrollExtent);
        await tester.pump();
        _expectWithin(ringed(0), viewport, 'the first choice at the top');
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
        _expectWithin(
          ringed(count - 1),
          viewport,
          'the last choice at the end',
        );
        // The scroll area ends above the footer after scrolling, too.
        expect(
          tester.getRect(find.byType(SessionFooterHintWidget)).top,
          greaterThanOrEqualTo(viewport.bottom - 0.01),
        );
        // Every choice in between becomes whole at some scroll offset.
        for (var i = 0; i < count; i++) {
          await tester.ensureVisible(choices.at(i));
          await tester.pump();
          _expectWithin(
            tester.getRect(choices.at(i)),
            viewport,
            'choice $i after scrolling to it',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
