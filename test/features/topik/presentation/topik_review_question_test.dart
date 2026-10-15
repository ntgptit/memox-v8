import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_review_question_widget.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

TopikAttemptAnswer _answer(TopikQuestion q, int? selected) =>
    TopikAttemptAnswer(
      questionNo: q.no,
      selectedIdx: selected,
      timeSpentMs: 30000,
      answeredAt: selected == null ? null : DateTime.utc(2026, 10, 15),
      correctIdx: q.answerIdx,
      points: q.points,
      pointsEarned: selected == q.answerIdx ? q.points : 0,
      questionType: q.questionType,
    );

// Screen 39's question (detail file 39; critique V2–V4; BR-TOPIK-006, -010).
void main() {
  final test = topikTestFixture();
  final first = test.questions.first; // answer 1, explanation and a word
  final second = test.questions[1]; // answer 2, no supporting content

  Future<void> host(WidgetTester tester, LibraryEnv env, Widget child) async {
    await pumpLibraryScreen(tester, env, Scaffold(body: child));
    await tester.pumpAndSettle();
  }

  List<MxChoiceTone> tones(WidgetTester tester) => [
    for (final tile in tester.widgetList<MxChoiceTile>(
      find.byType(MxChoiceTile),
    ))
      tile.tone,
  ];

  libraryTest('a wrong answer: the right option right, the choice wrong, '
      'nothing tappable; the explanation and the words in the UI language', (
    tester,
    env,
  ) async {
    await host(
      tester,
      env,
      TopikReviewQuestionWidget(
        question: first,
        answer: _answer(first, 3),
        isContentUpdated: false,
      ),
    );

    expect(tones(tester), [
      MxChoiceTone.right,
      MxChoiceTone.idle,
      MxChoiceTone.wrong,
      MxChoiceTone.idle,
    ]);
    expect(
      tester
          .widgetList<MxChoiceTile>(find.byType(MxChoiceTile))
          .every((tile) => tile.onTap == null),
      isTrue,
    );
    expect(findPlainText('Your answer ③ · Right answer ①'), findsOneWidget);
    expect(find.text('Explanation.'), findsOneWidget);
    expect(findPlainTextContaining('기획'), findsOneWidget);
    expect(findPlainTextContaining('planning'), findsOneWidget);
    expect(find.byType(MxInlineBanner), findsNothing);
  });

  libraryTest('a right answer with no supporting content: no section', (
    tester,
    env,
  ) async {
    await host(
      tester,
      env,
      TopikReviewQuestionWidget(
        question: second,
        answer: _answer(second, 2),
        isContentUpdated: false,
      ),
    );

    expect(tones(tester), [
      MxChoiceTone.idle,
      MxChoiceTone.right,
      MxChoiceTone.idle,
      MxChoiceTone.idle,
    ]);
    expect(find.text('Explanation'), findsNothing);
    expect(find.text('Words'), findsNothing);
  });

  libraryTest('not answered: only the right option marked, and it says so', (
    tester,
    env,
  ) async {
    await host(
      tester,
      env,
      TopikReviewQuestionWidget(
        question: second,
        answer: _answer(second, null),
        isContentUpdated: false,
      ),
    );

    expect(tones(tester), [
      MxChoiceTone.idle,
      MxChoiceTone.right,
      MxChoiceTone.idle,
      MxChoiceTone.idle,
    ]);
    expect(findPlainText('Not answered · Right answer ②'), findsOneWidget);
  });

  libraryTest('content updated after the attempt: the banner '
      '(BR-TOPIK-019)', (tester, env) async {
    await host(
      tester,
      env,
      TopikReviewQuestionWidget(
        question: second,
        answer: _answer(second, 2),
        isContentUpdated: true,
      ),
    );

    expect(
      find.text('This test was updated after this attempt'),
      findsOneWidget,
    );
    expect(find.text('Your score stays as it was.'), findsOneWidget);
  });

  libraryTest('the options say their state to TalkBack', (tester, env) async {
    final handle = tester.ensureSemantics();
    await host(
      tester,
      env,
      TopikReviewQuestionWidget(
        question: first,
        answer: _answer(first, 3),
        isContentUpdated: false,
      ),
    );

    expect(
      find.bySemanticsLabel('Option 1, 보기 1, the right answer'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Option 3, 보기 3, your answer, wrong'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
