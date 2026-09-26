@Tags(['golden'])
library;

import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// Screen 14's kit states that need a start: resume, starting, refused,
// startFailed; and the direction sheet (FE-A7).

final _en = lookupAppLocalizations(const Locale('en'));

StudyEntryScreen _screen(String deckId) => StudyEntryScreen(
  deckId: deckId,
  title: DeckStudyHeaderWidget(deckId: deckId, part: DeckStudyHeaderPart.title),
  breadcrumb: DeckStudyHeaderWidget(
    deckId: deckId,
    part: DeckStudyHeaderPart.breadcrumb,
  ),
  onOpenSession: (_) {},
);

/// The kit's sm2 frame without Hangul: 25 new, 4 due, two of them overdue.
Future<String> _sm2(LibraryEnv env) async {
  final root = await env.decks.root('TOPIK I', SchedulerType.sm2);
  final leaf = await env.decks.sub(root.id, 'Động từ');
  for (var i = 0; i < 25; i++) {
    await insertCard(env.db, id: 'n$i', deckId: leaf.id);
  }
  for (var i = 0; i < 4; i++) {
    await insertCard(
      env.db,
      id: 'd$i',
      deckId: leaf.id,
      back: 'meaning $i',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: i < 2 ? DateTime(2026, 9, 20) : DateTime(2026, 9, 24, 8),
    );
  }
  await lockScheduler(env.db, root.id);
  return leaf.id;
}

Future<void> _golden(WidgetTester tester, String name, String theme) =>
    expectBoundaryGolden(tester, 'goldens/study_entry_${name}_$theme.png');

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('study entry, resume, $theme', (tester, env) async {
      final leaf = await _sm2(env);
      await env.entries.openLearningSession(deckId: leaf);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(leaf), brightness);
        await _golden(tester, 'resume', theme);
      });
    });

    libraryTest('study entry, starting, $theme', (tester, env) async {
      final leaf = await _sm2(env);
      final gate = Completer<void>();
      env.entries.gate = gate.future;
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(leaf), brightness);
        await tester.tap(find.text(_en.studyEntryLearn));
        await tester.pump();
        await _golden(tester, 'starting', theme);
      });
      gate.complete();
      await tester.pumpAndSettle();
    });

    libraryTest('study entry, refused, $theme', (tester, env) async {
      final leaf = await _sm2(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(leaf), brightness);
        await tester.tap(find.text(_en.studyEntryReviewCta(4)));
        await tester.pumpAndSettle();
        // The due cards are reviewed elsewhere while the sheet is open.
        await env.db.customUpdate(
          'UPDATE card_schedule SET due_at = ? WHERE learned_at IS NOT NULL',
          variables: [Variable<DateTime>(DateTime(2026, 10, 1))],
          updates: {env.db.cardSchedule},
        );
        await tester.tap(find.text(_en.studyDirectionStart));
        await tester.pumpAndSettle();
        await _golden(tester, 'refused', theme);
      });
    });

    libraryTest('study entry, start failed, $theme', (tester, env) async {
      final leaf = await _sm2(env);
      env.entries.isFailing = true;
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(leaf), brightness);
        await tester.tap(find.text(_en.studyEntryLearn));
        await tester.pumpAndSettle();
        await _golden(tester, 'start_failed', theme);
      });
    });

    libraryTest('study entry, direction sheet, $theme', (tester, env) async {
      final leaf = await _sm2(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(leaf), brightness);
        await tester.tap(find.text(_en.studyEntryReviewCta(4)));
        await tester.pumpAndSettle();
        await _golden(tester, 'direction_sheet', theme);
      });
    });
  }
}
