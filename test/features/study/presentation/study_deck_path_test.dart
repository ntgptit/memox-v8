import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/support/study_deck_path_widget.dart';

import '../../../support/library_harness.dart';
import '../../../support/wrap_rule.dart';

// The deck path of the Study tab's Resume card and the Study Entry's resume
// banner (owner 2026-10-21): the whole path in two lines, the middle given
// way to "…" first, "›" kept with the deck after it, read whole.

const _crumb = ' › ';
const _elided = '…';

final _path = find.byType(StudyDeckPathWidget);

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  List<String> path, {
  double width = 328,
  double textScale = 1,
}) => pumpLibraryScreen(
  tester,
  env,
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: width,
      child: StudyDeckPathWidget(path: path),
    ),
  ),
  textScale: textScale,
);

/// The levels the path shows.
List<String> _shown(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: _path, matching: find.byType(Text)))
    .data!
    .split(_crumb);

bool _isCut(WidgetTester tester) => tester
    .renderObject<RenderParagraph>(
      find.descendant(of: _path, matching: find.byType(RichText)),
    )
    .didExceedMaxLines;

void main() {
  libraryTest('a path that fits reads whole, and two decks of one name '
      'under one root read apart, on screen and to TalkBack', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    for (final (path, spoken) in [
      (['Korean', 'Grammar', 'Lesson 1'], 'Lesson 1, in Grammar, in Korean'),
      (['Korean', 'Vocab', 'Lesson 1'], 'Lesson 1, in Vocab, in Korean'),
    ]) {
      await _pump(tester, env, path);
      expect(_shown(tester), path);
      expect(find.bySemanticsLabel(spoken), findsOneWidget);
    }
    handle.dispose();
  });

  libraryTest('a root alone is its name', (tester, env) async {
    await _pump(tester, env, ['Korean']);
    expect(find.text('Korean'), findsOneWidget);
    expect(find.textContaining(_elided), findsNothing);
  });

  // The deep tree: the root stays, then "…", then the levels nearest the
  // deck; nothing is cut, no line ends on "›", and TalkBack hears it all.
  for (final textScale in [1.0, 1.3]) {
    libraryTest('a deep path gives way in the middle, keeping the root and '
        'the levels nearest the deck (scale $textScale)', (tester, env) async {
      final handle = tester.ensureSemantics();
      const path = [
        'IELTS Academic Word List',
        'Sublist Collection Volume One',
        'Academic Reading Practice',
        'Chapter Seven Family and Home',
        'Lesson 1',
      ];
      await _pump(tester, env, path, textScale: textScale);

      final shown = _shown(tester);
      expect(shown.take(2), [path.first, _elided]);
      expect(path.sublist(path.length - (shown.length - 2)), shown.skip(2));
      expect(_isCut(tester), isFalse);
      expectNoLineEndsOn(tester, _path, '›');
      expect(
        find.bySemanticsLabel(
          'Lesson 1, in Chapter Seven Family and Home, in Academic Reading '
          'Practice, in Sublist Collection Volume One, in IELTS Academic '
          'Word List',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  }

  libraryTest('when the root alone fills the two lines, the deck keeps '
      'its place after "…"', (tester, env) async {
    await _pump(tester, env, [
      'IELTS Academic Word List Sublist Collection Volume One Academic '
          'Reading Practice Chapter Seven',
      'Lesson 1',
    ], width: 200);
    expect(_shown(tester), [_elided, 'Lesson 1']);
    expect(_isCut(tester), isFalse);
  });

  libraryTest('a deck name longer than two lines keeps the root and ends in '
      'an ellipsis', (tester, env) async {
    final deck = ('Academic Vocabulary for Reading ' * 4).trim();
    await _pump(tester, env, ['Korean', 'Grammar', deck]);
    expect(_shown(tester), ['Korean', _elided, deck]);
    expect(_isCut(tester), isTrue);
    expect(tester.takeException(), isNull);
  });
}
