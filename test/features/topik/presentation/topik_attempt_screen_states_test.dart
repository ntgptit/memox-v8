import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_attempt_use_case.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';
import 'package:memox/features/topik/presentation/providers/topik_attempt_provider.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_attempt_use_case_provider.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 37 (UC-TOPIK-003 E2, A4; BR-TOPIK-017, -019): listening, the
// attempt or its test gone, a read that fails, the language; each test is a
// row of detail file 37's Transitions table.
void main() {
  final reading = topikTestFixture();
  final listening = topikTestFixture(section: TopikSection.listening);

  libraryTest('listening: the group loads its clip, never plays it, and '
      'keeps it across its questions; another group loads its own '
      '(BR-TOPIK-017)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, listening, currentNo: 48);
    final player = FakeTopikAudioRepository();
    await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      catalog: [listening],
      player: player,
    );

    expect(player.calls, hasLength(1));
    expect(player.state.isPlaying, isFalse);
    // 48 → 49: another group, its own clip.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(player.calls, hasLength(2));
    // 49 → 50: the same group, the clip as it is.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(player.calls, hasLength(2));
    expect(player.state.isPlaying, isFalse);
  });

  libraryTest('audio that fails is a warning; answering still works '
      '(BR-TOPIK-017)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, listening);
    final player = FakeTopikAudioRepository()..failsLoads = true;
    await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      catalog: [listening],
      player: player,
    );

    expect(find.text("Couldn't play this audio"), findsOneWidget);
    await tester.tap(find.text('② 보기 2'));
    await tester.pumpAndSettle();
    expect(topikOptionTile(tester, '② 보기 2').tone, MxChoiceTone.selected);
  });

  libraryTest('the script shows once the question is answered, or by its '
      'toggle (spec §5.5, D15)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, listening);
    await pumpTopikAttempt(tester, env, attempt.id, catalog: [listening]);
    final script = listening.groups.first.script!;

    expect(find.text(script), findsNothing);
    await tester.tap(find.text('Show script'));
    await tester.pumpAndSettle();
    expect(find.text(script), findsOneWidget);
    await tester.tap(find.text('Hide script'));
    await tester.pumpAndSettle();
    expect(find.text(script), findsNothing);
    await tester.tap(find.text('① 보기 1'));
    await tester.pumpAndSettle();
    expect(find.text(script), findsNothing, reason: 'hidden by the person');

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('② 보기 2'));
    await tester.pumpAndSettle();
    expect(find.text(listening.groups[1].script!), findsOneWidget);
  });

  libraryTest('the attempt deleted elsewhere: missing, and Back to the test '
      'leaves (UC-TOPIK-003 E2)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, reading);
    final exits = await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      catalog: [reading],
    );

    await TopikAttemptRepositoryImpl(env.db).delete(attempt.id);
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Back to the test'));
    expect(exits.closes, 1);
  });

  libraryTest('the clock runs only while a question is on screen: the time '
      'before the attempt loads is not counted (BR-TOPIK-015)', (
    tester,
    env,
  ) async {
    final attempt = await topikSeedAttempt(env, reading);
    final gate = StreamController<TopikAttemptView?>();
    addTearDown(gate.close);
    await pumpLibraryScreen(
      tester,
      env,
      TopikAttemptScreen(
        attemptId: attempt.id,
        onClose: () {},
        onSubmitted: (_) {},
      ),
      overrides: [
        ...topikContentOverrides([reading]),
        topikAudioRepositoryProvider.overrideWithValue(
          FakeTopikAudioRepository(),
        ),
        topikAttemptProvider(attempt.id).overrideWith((ref) => gate.stream),
      ],
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Loading the attempt'), findsOneWidget);
    // Five seconds of loading, which belong to no question.
    topikWait(env, 5);
    final view = await tester.runAsync(
      () => WatchTopikAttemptUseCase(
        FakeTopikContentRepository([reading]),
        TopikAttemptRepositoryImpl(env.db),
      )(attempt.id).first,
    );
    gate.add(view);
    await tester.pumpAndSettle();
    expect(find.text('① 보기 1'), findsOneWidget);

    topikWait(env, 3);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final detail = await topikStoredAttempt(tester, env, attempt.id);
    expect(detail.answers.first.timeSpentMs, 3000);
    expect(detail.attempt.totalTimeMs, 3000);
  });

  libraryTest('a state with no question on screen writes no time: the '
      'attempt whose test changed keeps its 0 (BR-TOPIK-015, -019)', (
    tester,
    env,
  ) async {
    final attempt = await topikSeedAttempt(env, reading);
    await pumpTopikAttempt(tester, env, attempt.id, catalog: const []);
    expect(
      find.text("This test changed and can't be continued"),
      findsOneWidget,
    );

    topikWait(env, 5);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final detail = await topikStoredAttempt(tester, env, attempt.id);
    expect(detail.attempt.totalTimeMs, 0);
  });

  libraryTest('the test changed: the attempt offers Delete, which leaves '
      '(BR-TOPIK-019)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, reading);
    final exits = await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      catalog: const [],
    );

    expect(
      find.text("This test changed and can't be continued"),
      findsOneWidget,
    );
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Delete attempt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(exits.closes, 1);
    expect(
      await tester.runAsync(
        () => TopikAttemptRepositoryImpl(env.db).watchAttempt(attempt.id).first,
      ),
      isNull,
    );
  });

  libraryTest('a link to a submitted attempt offers its summary', (
    tester,
    env,
  ) async {
    final done = await topikSeedCompleted(
      env,
      reading,
      startedAt: libraryToday,
    );
    final exits = await pumpTopikAttempt(
      tester,
      env,
      done.id,
      catalog: [reading],
    );

    expect(find.text('This attempt was submitted'), findsOneWidget);
    await tester.tap(find.text('See summary'));
    expect(exits.submitted, [done.id]);
  });

  libraryTest('a read that fails: Retry reads again; Close stays', (
    tester,
    env,
  ) async {
    final attempt = await topikSeedAttempt(env, reading);
    var reads = 0;
    await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      overrides: [
        topikAttemptProvider(attempt.id).overrideWith((ref) {
          reads++;
          if (reads == 1) {
            return Stream<TopikAttemptView?>.error(StateError('read'));
          }
          return Stream.value(null);
        }),
      ],
      catalog: [reading],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
  });

  libraryTest('in Vietnamese: the same question, relabelled; the Korean '
      'stays (UC-TOPIK-003 A4)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, reading, currentNo: 2);
    await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      locale: const Locale('vi'),
      catalog: [reading],
    );

    expect(find.text('2. ${reading.questions[1].stemKo}'), findsOneWidget);
    expect(find.text('Câu sau'), findsOneWidget);
    expect(find.text('② 보기 2'), findsOneWidget);
  });

  libraryTest('a read that fails mid-attempt shows the error, with no footer '
      '(The Content Gate Rule)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, reading);
    await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      catalog: [reading],
      overrides: [
        topikAttemptProvider(attempt.id).overrideWith((ref) {
          // The store reads the attempt, then fails, as a locked database
          // does.
          final out = StreamController<TopikAttemptView?>();
          final read = ref.watch(watchTopikAttemptUseCaseProvider);
          final sub = read(attempt.id).listen((view) {
            out
              ..add(view)
              ..addError(const DatabaseLockedFailure(cause: 'locked'));
          });
          ref.onDispose(() {
            unawaited(sub.cancel());
            unawaited(out.close());
          });
          return out.stream;
        }),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Questions'), findsNothing);
    expect(find.byTooltip('Close'), findsOneWidget);
  });
}
