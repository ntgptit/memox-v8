@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/usecases/submit_topik_attempt_use_case.dart';
import 'package:memox/features/topik/presentation/providers/submit_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/topik_attempt_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';
import '../../../support/topik_screen_fixtures.dart';

/// The attempt store with a submit that never returns, so Submit spins; the
/// use case is final, so the wait sits under it.
final class _PendingSubmit implements TopikAttemptRepository {
  @override
  Future<Outcome<TopikAttempt, TopikRejection>> submit({
    required String attemptId,
    required TopikTest test,
    required int elapsedMs,
    DateTime? now,
  }) => Completer<Outcome<TopikAttempt, TopikRejection>>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Reading 96 with a real-length passage for group 1, so the two panes show
/// how they share the height.
TopikTest _reading() {
  final json = topikTestJson();
  groupJson(json, 'g1')['passage'] = {
    'textKo':
        '우리 회사는 다음 달부터 재택근무 제도를 시범적으로 운영합니다. '
        '희망하는 직원은 이번 주 금요일까지 팀장에게 신청서를 제출하면 됩니다. '
        '재택근무를 하는 날에도 오전 10시부터 오후 4시까지는 반드시 연락이 '
        '가능해야 하며, 주간 회의에는 화상으로 참여해야 합니다. 자세한 내용은 '
        '사내 게시판을 참고하시기 바랍니다.',
  };
  questionJson(json, 1)['stemKo'] = '이 글의 내용과 같은 것을 고르십시오.';
  return topikTestOfFixtureJson(json);
}

// Screen 37's states (detail file 37).
void main() {
  final reading = _reading();
  final listening = topikTestFixture(section: TopikSection.listening);
  final firstClip = TopikAudioClip(
    asset: listening.audioAsset!,
    startMs: listening.groups.first.audio!.startMs,
    endMs: listening.groups.first.audio!.endMs,
  );

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      String attemptId, {
      List<TopikTest>? catalog,
      FakeTopikAudioRepository? player,
      List<Override> overrides = const [],
      Future<void> Function()? before,
      bool settles = true,
    }) => withRealShadows(() async {
      await pumpLibraryGolden(
        tester,
        env,
        TopikAttemptScreen(
          attemptId: attemptId,
          onClose: () {},
          onSubmitted: (_) {},
        ),
        brightness,
        overrides: [
          ...topikContentOverrides(catalog ?? [reading, listening]),
          topikAudioRepositoryProvider.overrideWithValue(
            player ?? FakeTopikAudioRepository(),
          ),
          ...overrides,
        ],
      );
      await tester.pump(const Duration(seconds: 1));
      if (before != null) {
        await before();
        if (settles) {
          await tester.pumpAndSettle();
        } else {
          // Two frames: the buttons' disabled colours run through Material's
          // AnimatedTheme, which starts on the first.
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        }
      }
      await expectBoundaryGolden(
        tester,
        'goldens/topik_attempt_${state}_$theme.png',
      );
    });

    libraryTest('answering, $theme', (tester, env) async {
      final attempt = await topikSeedAttempt(env, reading, answers: {1: 2});
      await shoot(tester, env, 'reading', attempt.id);
    });

    libraryTest('answeringListening, $theme', (tester, env) async {
      final attempt = await topikSeedAttempt(env, listening);
      final player = FakeTopikAudioRepository(
        TopikAudioState(
          status: TopikAudioStatus.ready,
          clip: firstClip,
          positionMs: 12000,
          speed: 1,
        ),
      );
      await shoot(tester, env, 'listening', attempt.id, player: player);
    });

    libraryTest('scriptShown, $theme', (tester, env) async {
      final attempt = await topikSeedAttempt(env, listening, answers: {1: 3});
      await shoot(tester, env, 'script', attempt.id);
    });

    libraryTest('collapsed, $theme', (tester, env) async {
      final attempt = await topikSeedAttempt(env, reading, answers: {1: 2});
      await shoot(
        tester,
        env,
        'collapsed',
        attempt.id,
        before: () => tester.tap(find.text('Hide passage')),
      );
    });

    libraryTest('grid, $theme', (tester, env) async {
      final attempt = await topikSeedAttempt(
        env,
        reading,
        currentNo: 12,
        answers: {for (var no = 1; no <= 11; no++) no: no % 4 + 1},
      );
      await shoot(
        tester,
        env,
        'grid',
        attempt.id,
        before: () => tester.tap(find.text('Questions')),
      );
    });

    libraryTest('submitConfirm, $theme', (tester, env) async {
      final attempt = await topikSeedAttempt(
        env,
        reading,
        currentNo: 50,
        answers: {
          for (final question in reading.questions.take(47)) question.no: 1,
        },
      );
      await shoot(
        tester,
        env,
        'submit_confirm',
        attempt.id,
        before: () => tester.tap(find.text('Submit')),
      );
    });

    libraryTest('submitting, $theme', (tester, env) async {
      final attempt = await topikSeedAttempt(
        env,
        reading,
        currentNo: 50,
        answers: {for (final question in reading.questions) question.no: 1},
      );
      await shoot(
        tester,
        env,
        'submitting',
        attempt.id,
        overrides: [
          submitTopikAttemptUseCaseProvider.overrideWith(
            (ref) => SubmitTopikAttemptUseCase(
              FakeTopikContentRepository([reading]),
              _PendingSubmit(),
            ),
          ),
        ],
        before: () => tester.tap(find.text('Submit')),
        settles: false,
      );
    });

    libraryTest('audioError, $theme', (tester, env) async {
      final attempt = await topikSeedAttempt(env, listening);
      await shoot(
        tester,
        env,
        'audio_error',
        attempt.id,
        player: FakeTopikAudioRepository()..failsLoads = true,
      );
    });

    libraryTest('attemptMissing, $theme', (tester, env) async {
      await shoot(tester, env, 'missing', 'gone');
    });

    libraryTest('contentMissing, $theme', (tester, env) async {
      final attempt = await topikSeedAttempt(env, reading);
      await shoot(tester, env, 'content_missing', attempt.id, catalog: []);
    });

    libraryTest('submitted, $theme', (tester, env) async {
      final done = await topikSeedCompleted(
        env,
        reading,
        startedAt: libraryToday,
      );
      await shoot(tester, env, 'submitted', done.id);
    });

    libraryTest('loading, $theme', (tester, env) async {
      final pending = StreamController<TopikAttemptView?>();
      addTearDown(pending.close);
      await shoot(
        tester,
        env,
        'loading',
        'a1',
        overrides: [
          topikAttemptProvider('a1').overrideWith((ref) => pending.stream),
        ],
      );
    });

    libraryTest('error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'error',
        'a1',
        overrides: [
          topikAttemptProvider('a1').overrideWith(
            (ref) => Stream<TopikAttemptView?>.error(StateError('read')),
          ),
        ],
      );
    });
  }
}
