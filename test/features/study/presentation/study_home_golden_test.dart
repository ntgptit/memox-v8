@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/providers/study_home_provider.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_practice_entry_widget.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/sync_fakes.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 13 (FE-A8 P6) against the kit's frames: its decks, with the Korean
// name in Vietnamese (goldens render Latin and Vietnamese only).

const _longName =
    'Thuật ngữ Kinh tế – Tài chính – Ngân hàng cho kỳ thi chứng chỉ quốc tế: '
    'kế toán, kiểm toán, thị trường chứng khoán, bảo hiểm và cụm từ thường gặp';

StudyHomeScreen _screen() => StudyHomeScreen(
  onOpenSession: (_) {},
  onOpenDeck: (_) {},
  onOpenLibrary: () {},
  onOpenStarterDecks: () {},
  onOpenSync: () {},
  // The TOPIK entry `app/` composes into the slot (detail file 13, DEV-394).
  practiceEntry: TopikPracticeEntryWidget(onOpen: () {}),
);

final _overdue = DateTime(2026, 9, 20);
final _today = DateTime(2026, 9, 24, 8);
final _resting = DateTime(2026, 9, 25);

/// A root and its "Words" leaf holding the given cards; returns the leaf.
Future<String> _deck(
  LibraryEnv env,
  String name, {
  SchedulerType type = SchedulerType.eightBox,
  int overdue = 0,
  int today = 0,
  int fresh = 0,
  int resting = 0,
}) async {
  final root = await env.decks.root(name, type);
  final leaf = await env.decks.sub(root.id, 'Words');
  var n = 0;
  Future<void> card(DateTime? dueAt) => insertCard(
    env.db,
    id: '${root.id}-${n++}',
    deckId: leaf.id,
    back: '$name ${n + 1}',
    example: 'example',
    learnedAt: dueAt == null ? null : DateTime(2026, 9, 1),
    dueAt: dueAt,
    box: 2,
  );
  for (var i = 0; i < overdue; i++) {
    await card(_overdue);
  }
  for (var i = 0; i < today; i++) {
    await card(_today);
  }
  for (var i = 0; i < fresh; i++) {
    await card(null);
  }
  for (var i = 0; i < resting; i++) {
    await card(_resting);
  }
  if (overdue + today + resting > 0) await lockScheduler(env.db, root.id);
  return leaf.id;
}

Future<String> _library(LibraryEnv env) async {
  final ielts = await _deck(
    env,
    'IELTS Academic Word List',
    overdue: 3,
    today: 2,
    fresh: 4,
    resting: 1,
  );
  await _deck(
    env,
    'Tiếng Hàn TOPIK I · Từ vựng',
    type: SchedulerType.sm2,
    overdue: 2,
    today: 1,
    fresh: 3,
  );
  await _deck(env, 'Tiếng Anh giao tiếp hằng ngày', today: 2, resting: 3);
  await _deck(env, 'IT', fresh: 2);
  await _deck(env, 'Korean Basics', type: SchedulerType.sm2, resting: 2);
  await env.decks.root(_longName);
  return ielts;
}

Future<void> _resume(LibraryEnv env, String leaf) async {
  final opened = await env.entries.openReviewSession(
    deckId: leaf,
    mode: StudyMode.match,
  );
  expect(opened, isA<Ok<String, StudyRejection>>());
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String name, {
      List<Override> overrides = const [],
      Finder? scrollTo,
      double textScale = 1,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(),
          brightness,
          textScale: textScale,
          overrides: [
            ...topikContentOverrides(topikScreenTests()),
            ...overrides,
          ],
        );
        if (scrollTo != null) {
          await tester.scrollUntilVisible(
            scrollTo,
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
        }
        await expectBoundaryGolden(
          tester,
          'goldens/study_home_${name}_$theme.png',
        );
      });
    }

    libraryTest('study home, loaded, $theme', (tester, env) async {
      await _resume(env, await _library(env));
      await shoot(tester, env, 'loaded');
    });

    // Resume drops under the progress as a block at a large text scale
    // (Study home spec H3).
    libraryTest('study home, resume at a 1.3 text scale, $theme', (
      tester,
      env,
    ) async {
      await _resume(env, await _library(env));
      await shoot(tester, env, 'resume_large_text', textScale: 1.3);
    });

    // A session three levels under its root: the card names it by its
    // path, the middle given way to "…" so it keeps two lines (owner
    // 2026-10-21).
    libraryTest('study home, resume of a deep deck, $theme', (
      tester,
      env,
    ) async {
      final ielts = await _library(env);
      final root = await rootOf(env.db, ielts);
      var parent = root;
      for (final name in [
        'Academic Reading Practice',
        'Unit 7: Family and Home',
        'Lesson 12',
      ]) {
        parent = (await env.decks.sub(parent, name)).id;
      }
      for (var i = 0; i < 3; i++) {
        await insertCard(
          env.db,
          id: 'deep-$i',
          deckId: parent,
          back: 'deep ${i + 1}',
          learnedAt: DateTime(2026, 9, 1),
          dueAt: _overdue,
          box: 2,
        );
      }
      await lockScheduler(env.db, root);
      await _resume(env, parent);
      await shoot(tester, env, 'resume_deep_deck');
    });

    libraryTest('study home, no resume, $theme', (tester, env) async {
      await _library(env);
      await shoot(tester, env, 'no_resume');
    });

    // The practice slot below several decks, the common case the frames
    // above crop (audit 2026-10-19, G6).
    libraryTest('study home, scrolled to practice, $theme', (
      tester,
      env,
    ) async {
      await _library(env);
      await shoot(
        tester,
        env,
        'scrolled',
        scrollTo: find.byType(TopikPracticeEntryWidget),
      );
    });

    libraryTest('study home, caught up, $theme', (tester, env) async {
      await _deck(env, 'Korean Basics', resting: 4);
      await _deck(env, 'IELTS Academic Word List', resting: 6);
      await shoot(tester, env, 'zero');
    });

    // Only new cards wait: nothing is due, the rows hold the counts (Study
    // home spec §4).
    libraryTest('study home, new cards only, $theme', (tester, env) async {
      await _deck(env, 'IT', fresh: 2);
      await _deck(env, 'Korean Basics', resting: 2);
      await shoot(tester, env, 'new_only');
    });

    libraryTest('study home, no decks, $theme', (tester, env) async {
      await shoot(tester, env, 'no_decks');
    });

    libraryTest('study home, no cards, $theme', (tester, env) async {
      await env.decks.root('IELTS Academic Word List');
      await env.decks.root('Korean Basics');
      await shoot(tester, env, 'no_cards');
    });

    libraryTest('study home, loading, $theme', (tester, env) async {
      final never = StreamController<StudyHome>();
      addTearDown(never.close);
      await shoot(
        tester,
        env,
        'loading',
        overrides: [studyHomeProvider.overrideWith((ref) => never.stream)],
      );
    });

    libraryTest('study home, error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'error',
        overrides: [
          studyHomeProvider.overrideWith(
            (ref) => Stream<StudyHome>.error(StateError('read failed')),
          ),
        ],
      );
    });

    libraryTest('study home, sync rejected, $theme', (tester, env) async {
      await _library(env);
      await shoot(
        tester,
        env,
        'sync_rejected',
        overrides: syncOverrides(const SyncStatus(rejectedCount: 2)),
      );
    });

    libraryTest('study home, sync stale, $theme', (tester, env) async {
      await _library(env);
      await shoot(
        tester,
        env,
        'sync_stale',
        overrides: syncOverrides(
          SyncStatus(
            pendingCount: 3,
            oldestPendingAt: env.clock.now().subtract(
              const Duration(hours: 30),
            ),
          ),
        ),
      );
    });
  }
}
