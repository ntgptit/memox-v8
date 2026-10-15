@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_review_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_review_screen.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';
import '../../../support/topik_screen_fixtures.dart';

/// Reading 96 with question 1's full supporting content and a real passage.
TopikTest _reading({int contentVersion = 1}) {
  final json = topikTestJson()..['contentVersion'] = contentVersion;
  groupJson(json, 'g1')['passage'] = {
    'textKo':
        '우리 회사는 다음 달부터 재택근무 제도를 시범적으로 운영합니다. '
        '희망하는 직원은 이번 주 금요일까지 팀장에게 신청서를 제출하면 됩니다.',
  };
  questionJson(json, 1)
    ..['stemKo'] = '이 글의 내용과 같은 것을 고르십시오.'
    ..['explanation'] = {
      'vi': 'Đoạn văn nói nhân viên nộp đơn trước thứ Sáu.',
      'en': 'The notice says staff apply by Friday.',
    }
    ..['translation'] = {
      'vi': 'Công ty chúng tôi thử nghiệm làm việc tại nhà từ tháng sau.',
      'en': 'Our company trials working from home from next month.',
    };
  return topikTestOfFixtureJson(json);
}

// Screen 39's states (detail file 39).
void main() {
  final reading = _reading();
  final listening = topikTestFixture(section: TopikSection.listening);

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      String attemptId, {
      int? questionNo,
      List<TopikTest>? catalog,
      List<Override> overrides = const [],
    }) => withRealShadows(() async {
      await pumpLibraryGolden(
        tester,
        env,
        TopikReviewScreen(
          attemptId: attemptId,
          initialQuestionNo: questionNo,
          onBack: () {},
          onBackToSummary: () {},
        ),
        brightness,
        overrides: [
          ...topikContentOverrides(catalog ?? [reading, listening]),
          topikAudioRepositoryProvider.overrideWithValue(
            FakeTopikAudioRepository(),
          ),
          ...overrides,
        ],
      );
      await tester.pump(const Duration(seconds: 1));
      await expectBoundaryGolden(
        tester,
        'goldens/topik_review_${state}_$theme.png',
      );
    });

    Future<String> submitted(LibraryEnv env, TopikTest test) async =>
        (await topikSeedSubmitted(
          env,
          test,
          answers: {
            test.questions[0].no: test.questions[0].answerIdx % 4 + 1,
            test.questions[1].no: test.questions[1].answerIdx,
          },
        )).id;

    libraryTest('wrong, $theme', (tester, env) async {
      await shoot(tester, env, 'wrong', await submitted(env, reading));
    });

    libraryTest('correct, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'correct',
        await submitted(env, reading),
        questionNo: 2,
      );
    });

    libraryTest('unanswered, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'unanswered',
        await submitted(env, reading),
        questionNo: 3,
      );
    });

    libraryTest('listening, $theme', (tester, env) async {
      await shoot(tester, env, 'listening', await submitted(env, listening));
    });

    libraryTest('contentUpdated, $theme', (tester, env) async {
      final id = await submitted(env, reading);
      await shoot(
        tester,
        env,
        'updated',
        id,
        questionNo: 2,
        catalog: [_reading(contentVersion: 2)],
      );
    });

    libraryTest('contentMissing, $theme', (tester, env) async {
      final id = await submitted(env, reading);
      await shoot(tester, env, 'content_missing', id, catalog: const []);
    });

    libraryTest('attemptMissing, $theme', (tester, env) async {
      await shoot(tester, env, 'missing', 'gone');
    });

    libraryTest('loading, $theme', (tester, env) async {
      final pending = StreamController<TopikReviewView?>();
      addTearDown(pending.close);
      await shoot(
        tester,
        env,
        'loading',
        'a1',
        overrides: [
          topikReviewProvider('a1').overrideWith((ref) => pending.stream),
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
          topikReviewProvider('a1').overrideWith(
            (ref) => Stream<TopikReviewView?>.error(StateError('read')),
          ),
        ],
      );
    });
  }
}
