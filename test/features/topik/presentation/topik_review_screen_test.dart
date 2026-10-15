import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_review_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_review_screen.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';
import '../../../support/topik_screen_fixtures.dart';

final class _Exits {
  var backs = 0;
  var summaries = 0;
}

// Screen 39 (UC-TOPIK-005; BR-TOPIK-006, -010, -017, -019): each test is a
// row of detail file 39's Transitions table.
void main() {
  final reading = topikTestFixture();

  /// 1 wrong, 2 right, 3 wrong, the rest blank.
  Map<int, int> mixed(TopikTest test) {
    final q = test.questions;
    return {
      q[0].no: q[0].answerIdx % 4 + 1,
      q[1].no: q[1].answerIdx,
      q[2].no: q[2].answerIdx % 4 + 1,
    };
  }

  Future<_Exits> pump(
    WidgetTester tester,
    LibraryEnv env,
    String attemptId, {
    int? questionNo,
    List<TopikTest>? catalog,
    List<Override> overrides = const [],
  }) async {
    final exits = _Exits();
    await pumpLibraryScreen(
      tester,
      env,
      TopikReviewScreen(
        attemptId: attemptId,
        initialQuestionNo: questionNo,
        onBack: () => exits.backs++,
        onBackToSummary: () => exits.summaries++,
      ),
      overrides: [
        ...topikContentOverrides(catalog ?? [reading]),
        topikAudioRepositoryProvider.overrideWithValue(
          FakeTopikAudioRepository(),
        ),
        ...overrides,
      ],
    );
    await tester.pumpAndSettle();
    return exits;
  }

  List<MxChoiceTone> tones(WidgetTester tester) => [
    for (final tile in tester.widgetList<MxChoiceTile>(
      find.byType(MxChoiceTile),
    ))
      tile.tone,
  ];

  libraryTest('opens the question asked, with its real number; an unknown '
      'number opens the first (UC-TOPIK-005, A3)', (tester, env) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: mixed(reading),
    );
    await pump(tester, env, done.id, questionNo: 2);
    expect(find.text('Review · 2 / 50'), findsOneWidget);
    expect(tones(tester)[1], MxChoiceTone.right);

    await pump(tester, env, done.id, questionNo: 99);
    expect(find.text('Review · 1 / 50'), findsOneWidget);
  });

  libraryTest('Next and Previous walk the filter; a filter opens its first '
      'question; the last says Done (UC-TOPIK-005 step 4)', (
    tester,
    env,
  ) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: mixed(reading),
    );
    final exits = await pump(tester, env, done.id);

    await tester.tap(find.text('Wrong'));
    await tester.pumpAndSettle();
    expect(find.text('Review · 1 / 50'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Review · 3 / 50'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Review · 1 / 50'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    expect(exits.backs, 1);
  });

  libraryTest('a filter opens its first question, even when the one shown is '
      'in it (UC-TOPIK-005 A3)', (tester, env) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: mixed(reading),
    );
    await pump(tester, env, done.id, questionNo: 5);
    expect(find.text('Review · 5 / 50'), findsOneWidget);

    final unanswered = find.widgetWithText(MxFilterChip, 'Unanswered');
    await tester.ensureVisible(unanswered);
    await tester.tap(unanswered);
    await tester.pumpAndSettle();
    expect(find.text('Review · 4 / 50'), findsOneWidget);
  });

  libraryTest('the selected filter tapped again keeps the place', (
    tester,
    env,
  ) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: mixed(reading),
    );
    await pump(tester, env, done.id);

    final wrong = find.widgetWithText(MxFilterChip, 'Wrong');
    await tester.tap(wrong);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Review · 3 / 50'), findsOneWidget);
    await tester.tap(wrong);
    await tester.pumpAndSettle();
    expect(find.text('Review · 3 / 50'), findsOneWidget);
  });

  libraryTest('a filter with no question cannot be picked', (
    tester,
    env,
  ) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: {for (final q in reading.questions) q.no: q.answerIdx},
    );
    await pump(tester, env, done.id);

    final wrong = tester.widget<MxFilterChip>(
      find.widgetWithText(MxFilterChip, 'Wrong'),
    );
    expect(wrong.onSelected, isNull);
  });

  libraryTest('an option tapped changes nothing and writes nothing '
      '(BR-TOPIK-010)', (tester, env) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: mixed(reading),
    );
    await pump(tester, env, done.id);

    await tester.tap(find.text('④ 보기 4'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tones(tester)[3], MxChoiceTone.idle);
    final stored = await topikStoredAttempt(tester, env, done.id);
    expect(
      stored.answers.first.selectedIdx,
      reading.questions.first.answerIdx % 4 + 1,
    );
  });

  libraryTest('content updated after the attempt: the banner '
      '(BR-TOPIK-019)', (tester, env) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: mixed(reading),
    );
    final updated = topikTestJson()..['contentVersion'] = 2;
    await pump(
      tester,
      env,
      done.id,
      catalog: [topikTestOfFixtureJson(updated)],
    );

    expect(
      find.text('This test was updated after this attempt'),
      findsOneWidget,
    );
  });

  libraryTest('the test gone: Review is unavailable, Back to summary '
      '(BR-TOPIK-019)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading);
    final exits = await pump(tester, env, done.id, catalog: const []);

    expect(find.text("Review isn't available for this test"), findsOneWidget);
    expect(find.text('Your score is still in the summary.'), findsOneWidget);
    await tester.tap(find.text('Back to summary'));
    expect(exits.summaries, 1);
  });

  libraryTest('the attempt deleted elsewhere, or still in progress: missing '
      '(UC-TOPIK-005 E2)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading);
    final exits = await pump(tester, env, done.id);
    await TopikAttemptRepositoryImpl(env.db).delete(done.id);
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
    await tester.tap(find.text('Back to the test'));
    expect(exits.backs, 1);

    final open = await topikSeedAttempt(env, reading);
    await pump(tester, env, open.id);
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
  });

  libraryTest('TOPIK I reading: ?q=31 opens question 31 (BR-TOPIK-001)', (
    tester,
    env,
  ) async {
    final t1 = topikTestFixture(level: TopikLevel.topik1);
    final done = await topikSeedSubmitted(env, t1);
    await pump(tester, env, done.id, questionNo: 31, catalog: [t1]);

    expect(find.text('Review · 31 / 70'), findsOneWidget);
  });

  libraryTest('listening: the audio bar and the script, open '
      '(BR-TOPIK-017)', (tester, env) async {
    final listening = topikTestFixture(section: TopikSection.listening);
    final done = await topikSeedSubmitted(env, listening);
    await pump(tester, env, done.id, catalog: [listening]);

    expect(find.byType(TopikAudioBarWidget), findsOneWidget);
    expect(find.text(listening.groups.first.script!), findsOneWidget);
  });

  libraryTest('a read that fails: Retry reads again', (tester, env) async {
    var reads = 0;
    final done = await topikSeedSubmitted(env, reading);
    await pump(
      tester,
      env,
      done.id,
      overrides: [
        topikReviewProvider(done.id).overrideWith((ref) {
          reads++;
          if (reads == 1) {
            return Stream<TopikReviewView?>.error(StateError('read'));
          }
          return Stream.value(null);
        }),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
  });
}
