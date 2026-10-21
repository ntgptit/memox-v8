import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/support/study_deck_path_widget.dart';

import '../../../support/library_harness.dart';
import '../../../support/wrap_rule.dart';

// The deck path of the Study tab's Resume card and the Study Entry's resume
// banner (owner 2026-10-21): the whole path in two lines; when it does not
// fit, the deck and the levels nearest it stay, the levels above give way
// to "…", and the root stays only while there is room; "›" kept with the
// deck after it; read whole.

/// What `breadcrumbLine` joins levels with: a "›" glued by a no-break space
/// to the level after it.
const _crumb = ' › ';
const _elided = '…';

/// The content width of 13's Resume title (beside its tile) and of 14's
/// banner, on a 360 dp phone.
const _resumeTitleWidth = 232.0;
const _bannerWidth = 280.0;

final _path = find.byType(StudyDeckPathWidget);

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  List<String> path, {
  double width = _bannerWidth,
  double textScale = 1,
  bool isBold = false,
}) => pumpLibraryScreen(
  tester,
  env,
  Align(
    alignment: Alignment.topLeft,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(boldText: isBold),
        child: SizedBox(
          width: width,
          child: StudyDeckPathWidget(path: path),
        ),
      ),
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

  // The ancestors farthest from the deck give way first, the root among
  // them, at 13's and 14's widths and a 1.3 text scale; TalkBack still hears
  // every level.
  const deep = [
    'IELTS Academic Word List Sublist Collection',
    'Reading',
    'Unit 7: Family and Home',
    'Lesson 12',
  ];
  for (final (width, textScale, shown) in [
    (_resumeTitleWidth, 1.0, [_elided, ...deep.skip(1)]),
    (_resumeTitleWidth, 1.3, [_elided, ...deep.skip(2)]),
    (_bannerWidth, 1.0, [_elided, ...deep.skip(1)]),
    (_bannerWidth, 1.3, [_elided, ...deep.skip(1)]),
  ]) {
    libraryTest('a deep path keeps the deck and its nearest levels first '
        '(width $width, scale $textScale)', (tester, env) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, env, deep, width: width, textScale: textScale);

      expect(_shown(tester), shown);
      expect(_isCut(tester), isFalse);
      expectNoLineEndsOn(tester, _path, '›');
      expect(
        find.bySemanticsLabel(
          'Lesson 12, in Unit 7: Family and Home, in Reading, in IELTS '
          'Academic Word List Sublist Collection',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  }

  // The fit is measured as the text is drawn, bold text and the text scale
  // included: across every width the deck is never cut and no line ends on
  // "›".
  for (final (textScale, isBold) in [
    (1.0, true),
    (1.3, false),
    (1.3, true),
    (2.0, true),
  ]) {
    libraryTest('the deck is never cut at any width (scale $textScale, bold '
        '$isBold)', (tester, env) async {
      const path = [
        'Tiếng Hàn TOPIK I',
        'Từ vựng sơ cấp',
        'Chủ đề gia đình và trường học',
        'Bài 12',
        'Động từ thường gặp',
      ];
      for (var width = 200.0; width <= 360; width += 8) {
        await _pump(
          tester,
          env,
          path,
          width: width,
          textScale: textScale,
          isBold: isBold,
        );
        expect(_isCut(tester), isFalse, reason: 'width $width');
        expect(_shown(tester).last, path.last, reason: 'width $width');
        expectNoLineEndsOn(tester, _path, '›');
      }
      expect(tester.takeException(), isNull);
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

  libraryTest('a deck name longer than two lines starts the first line after '
      '"…" and only its own end is cut', (tester, env) async {
    final deck = ('Academic Vocabulary for Reading ' * 4).trim();
    await _pump(tester, env, ['Korean', 'Grammar', deck]);
    expect(_shown(tester), [_elided, deck]);
    expect(_isCut(tester), isTrue);
    expect(tester.takeException(), isNull);
  });
}
