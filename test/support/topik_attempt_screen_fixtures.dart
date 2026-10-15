import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';

import 'library_harness.dart';
import 'topik_attempt_fixtures.dart';
import 'topik_fakes.dart';
import 'topik_screen_fixtures.dart';

/// An attempt of [test] in progress, started on the test day, with
/// [answers] (question → option) chosen and [currentNo] current.
Future<TopikAttempt> topikSeedAttempt(
  LibraryEnv env,
  TopikTest test, {
  int? currentNo,
  Map<int, int> answers = const {},
}) async {
  final store = TopikAttemptRepositoryImpl(env.db);
  final attempt = topikOk(await store.start(test, now: libraryToday));
  for (final MapEntry(key: no, value: idx) in answers.entries) {
    topikOk(
      await store.answer(
        attemptId: attempt.id,
        questionNo: no,
        selectedIdx: idx,
        elapsedMs: 0,
        now: libraryToday,
      ),
    );
  }
  if (currentNo != null) {
    topikOk(
      await store.move(
        attemptId: attempt.id,
        toQuestionNo: currentNo,
        elapsedMs: 0,
        now: libraryToday,
      ),
    );
  }
  return attempt;
}

/// Where screen 37 was asked to go.
final class TopikAttemptExits {
  var closes = 0;
  final submitted = <String>[];
}

/// Screen 37 on [attemptId] over [catalog], with a fake player.
Future<TopikAttemptExits> pumpTopikAttempt(
  WidgetTester tester,
  LibraryEnv env,
  String attemptId, {
  required List<TopikTest> catalog,
  FakeTopikAudioRepository? player,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) async {
  final exits = TopikAttemptExits();
  await pumpLibraryScreen(
    tester,
    env,
    TopikAttemptScreen(
      attemptId: attemptId,
      onClose: () => exits.closes++,
      onSubmitted: exits.submitted.add,
    ),
    locale: locale,
    overrides: [
      ...topikContentOverrides(catalog),
      topikAudioRepositoryProvider.overrideWithValue(
        player ?? FakeTopikAudioRepository(),
      ),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
  return exits;
}

/// The attempt [id] as the store holds it now.
Future<TopikAttemptDetail> topikStoredAttempt(
  WidgetTester tester,
  LibraryEnv env,
  String id,
) async => (await tester.runAsync(
  () => TopikAttemptRepositoryImpl(env.db).watchAttempt(id).first,
))!;

/// The option tile that shows [text].
MxChoiceTile topikOptionTile(WidgetTester tester, String text) => tester.widget(
  find.ancestor(of: find.text(text), matching: find.byType(MxChoiceTile)),
);

/// The test clock moved on by [seconds].
void topikWait(LibraryEnv env, int seconds) =>
    env.clock.current = env.clock.current.add(Duration(seconds: seconds));

/// A submitted attempt of [test] with [answers] (question → option) chosen
/// in that order; each answer gives the question before it a different time,
/// so the chart has varied bars.
Future<TopikAttempt> topikSeedSubmitted(
  LibraryEnv env,
  TopikTest test, {
  Map<int, int> answers = const {},
}) async {
  final store = TopikAttemptRepositoryImpl(env.db);
  final attempt = topikOk(await store.start(test, now: libraryToday));
  var stepMs = 20000;
  for (final MapEntry(key: no, value: idx) in answers.entries) {
    topikOk(
      await store.answer(
        attemptId: attempt.id,
        questionNo: no,
        selectedIdx: idx,
        elapsedMs: stepMs,
        now: libraryToday,
      ),
    );
    stepMs = stepMs % 150000 + 35000;
  }
  return topikOk(
    await store.submit(
      attemptId: attempt.id,
      test: test,
      elapsedMs: 45000,
      now: libraryToday.add(const Duration(minutes: 50)),
    ),
  );
}
