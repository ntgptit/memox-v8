import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

import 'library_harness.dart';
import 'topik_attempt_fixtures.dart';
import 'topik_content_fixtures.dart';
import 'topik_fakes.dart';

/// The catalog the TOPIK screens are shown with: TOPIK I reading 91 and 96,
/// listening 96; TOPIK II reading 83, 91 and 96, listening 96.
List<TopikTest> topikScreenTests() => [
  for (final round in [91, 96])
    topikTestFixture(level: TopikLevel.topik1, round: round),
  topikTestFixture(level: TopikLevel.topik1, section: TopikSection.listening),
  for (final round in [83, 91, 96]) topikTestFixture(round: round),
  topikTestFixture(section: TopikSection.listening),
];

/// The bundled content replaced by [tests]; the attempt store is the
/// harness's database.
List<Override> topikContentOverrides(List<TopikTest> tests) => [
  topikContentRepositoryProvider.overrideWithValue(
    FakeTopikContentRepository(tests),
  ),
];

/// A completed attempt of [test], started at [startedAt], with the first
/// [correct] questions right and the rest unanswered, taking [elapsedMs].
Future<TopikAttempt> topikSeedCompleted(
  LibraryEnv env,
  TopikTest test, {
  required DateTime startedAt,
  int correct = 10,
  int elapsedMs = 600000,
}) async {
  final store = TopikAttemptRepositoryImpl(env.db);
  final attempt = topikOk(await store.start(test, now: startedAt));
  for (final question in test.questions.take(correct)) {
    topikOk(
      await store.answer(
        attemptId: attempt.id,
        questionNo: question.no,
        selectedIdx: question.answerIdx,
        elapsedMs: 0,
        now: startedAt,
      ),
    );
  }
  return topikOk(
    await store.submit(
      attemptId: attempt.id,
      test: test,
      elapsedMs: elapsedMs,
      now: startedAt.add(Duration(milliseconds: elapsedMs)),
    ),
  );
}

/// An attempt of [test] in progress, started at [startedAt].
Future<TopikAttempt> topikSeedInProgress(
  LibraryEnv env,
  TopikTest test, {
  required DateTime startedAt,
}) async => topikOk(
  await TopikAttemptRepositoryImpl(env.db).start(test, now: startedAt),
);

/// A [Text] that reads [text], or an [MxTermLine] that reads it as a whole
/// line (the TOPIK meta lines are lines of terms, The Wrap Rule); a term's
/// own text inside a line is not counted again.
Finder findPlainText(String text) => _plainLine((line) => line == text);

/// [findPlainText] for a line that contains [text].
Finder findPlainTextContaining(String text) =>
    _plainLine((line) => line.contains(text));

Finder _plainLine(bool Function(String line) reads) =>
    find.byElementPredicate((element) {
      final widget = element.widget;
      if (widget is MxTermLine) return reads(widget.spoken);
      if (widget is! Text) return false;
      if (element.findAncestorWidgetOfExactType<MxTermLine>() != null) {
        return false;
      }
      return reads(widget.data ?? '');
    });
