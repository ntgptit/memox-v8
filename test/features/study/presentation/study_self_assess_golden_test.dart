@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// Screen 16a has no kit frame: these goldens are its record (handoff 16a).

final _en = lookupAppLocalizations(const Locale('en'));

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

/// A review of "Động từ" whose first card is `ăn uống` (interval 10, two
/// repetitions, so the grades differ), with [others] more cards after it.
Future<String> _review(
  LibraryEnv env, {
  DirectionChoice direction = DirectionChoice.koreanToMeaning,
  int others = 1,
}) async {
  final root = await env.decks.root('TOPIK I', SchedulerType.sm2);
  final leaf = await env.decks.sub(root.id, 'Động từ');
  await insertCard(
    env.db,
    id: 'a',
    deckId: leaf.id,
    front: 'ăn uống',
    back: 'to eat and drink',
    pronunciation: 'an uong',
    example: 'Tôi ăn sáng lúc 7 giờ.',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 14),
    intervalDays: 10,
  );
  await env.db.customStatement(
    "UPDATE card_schedule SET repetitions = 2 WHERE card_id = 'a'",
  );
  for (var i = 0; i < others; i++) {
    await insertCard(
      env.db,
      id: 'b$i',
      deckId: leaf.id,
      front: 'đi bộ $i',
      back: 'to walk $i',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
  }
  await lockScheduler(env.db, root.id);
  final opened = await studyEntryRepository(env.db, env.clock.now)
      .openReviewSession(
        deckId: leaf.id,
        mode: StudyMode.selfAssess,
        direction: direction,
      );
  return (opened as Ok<String, StudyRejection>).value;
}

Future<void> _reveal(WidgetTester tester) async {
  await tester.tap(find.text(_en.studySelfAssessShowAnswer));
  await tester.pumpAndSettle();
}

Future<void> _golden(WidgetTester tester, String name, String theme) =>
    expectBoundaryGolden(
      tester,
      'goldens/study_self_assess_${name}_$theme.png',
    );

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('self-assess, prompt, $theme', (tester, env) async {
      final id = await _review(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(id), brightness);
        await tester.pumpAndSettle();
        await _golden(tester, 'prompt', theme);
      });
    });

    libraryTest('self-assess, revealed, $theme', (tester, env) async {
      final id = await _review(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(id), brightness);
        await tester.pumpAndSettle();
        await _reveal(tester);
        await _golden(tester, 'revealed', theme);
      });
    });

    libraryTest('self-assess, relearning, $theme', (tester, env) async {
      final id = await _review(env, others: 0);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(id), brightness);
        await tester.pumpAndSettle();
        await _reveal(tester);
        await tester.tap(find.text(_en.cardActionAgain));
        await tester.pumpAndSettle();
        await _reveal(tester);
        await _golden(tester, 'relearning', theme);
      });
    });

    libraryTest('self-assess, meaning first, $theme', (tester, env) async {
      final id = await _review(env, direction: DirectionChoice.meaningToKorean);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(id), brightness);
        await tester.pumpAndSettle();
        await _golden(tester, 'meaning_first', theme);
      });
    });

    libraryTest('self-assess, large text, $theme', (tester, env) async {
      final id = await _review(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(id),
          brightness,
          textScale: 2,
        );
        await tester.pumpAndSettle();
        await _reveal(tester);
        await _golden(tester, 'large_text', theme);
      });
    });
  }
}
