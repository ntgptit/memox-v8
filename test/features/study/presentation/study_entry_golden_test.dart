@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/presentation/providers/study_entry_provider.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

StudyEntryScreen _screen(String deckId) => StudyEntryScreen(
  deckId: deckId,
  title: DeckStudyHeaderWidget(deckId: deckId, part: DeckStudyHeaderPart.title),
  breadcrumb: DeckStudyHeaderWidget(
    deckId: deckId,
    part: DeckStudyHeaderPart.breadcrumb,
  ),
  onOpenSession: (_) {},
);

/// A learned card of [deckId], due at [due].
Future<void> _due(
  LibraryEnv env,
  String deckId,
  String id, {
  required String meaning,
  DateTime? due,
  String? example,
}) => insertCard(
  env.db,
  id: id,
  deckId: deckId,
  front: 'term $id',
  back: meaning,
  example: example,
  learnedAt: DateTime(2026, 9, 1),
  dueAt: due ?? DateTime(2026, 9, 24, 8),
  box: 2,
);

/// The kit's eightBox frame without Hangul (the test fonts have none): no
/// new card, 12 due on four meanings, three of them with an example.
Future<String> _eightBox(LibraryEnv env) async {
  final root = await env.decks.root('Tiếng Anh giao tiếp hằng ngày');
  final leaf = await env.decks.sub(root.id, 'Nhà hàng');
  for (var i = 0; i < 12; i++) {
    await _due(
      env,
      leaf.id,
      'd$i',
      meaning: 'meaning ${i % 4}',
      example: i < 3 ? 'example $i' : null,
    );
  }
  await lockScheduler(env.db, root.id);
  return leaf.id;
}

/// SM-2 with new and due cards, two of the due ones overdue.
Future<String> _sm2(LibraryEnv env) async {
  final root = await env.decks.root('TOPIK I', SchedulerType.sm2);
  final leaf = await env.decks.sub(root.id, 'Động từ');
  for (var i = 0; i < 25; i++) {
    await insertCard(env.db, id: 'n$i', deckId: leaf.id);
  }
  for (var i = 0; i < 4; i++) {
    await _due(
      env,
      leaf.id,
      'd$i',
      meaning: 'meaning $i',
      due: i < 2 ? DateTime(2026, 9, 20) : null,
    );
  }
  await lockScheduler(env.db, root.id);
  return leaf.id;
}

/// The kit's onlyNew frame: SM-2, new cards only.
Future<String> _onlyNew(LibraryEnv env) async {
  final root = await env.decks.root('TOPIK I', SchedulerType.sm2);
  final leaf = await env.decks.sub(root.id, 'Động từ');
  for (var i = 0; i < 25; i++) {
    await insertCard(env.db, id: 'n$i', deckId: leaf.id);
  }
  return leaf.id;
}

/// Every card learned and resting.
Future<String> _nothing(LibraryEnv env) async {
  final root = await env.decks.root('TOPIK I');
  await _due(env, root.id, 'later', meaning: 'm', due: DateTime(2026, 10, 1));
  await lockScheduler(env.db, root.id);
  return root.id;
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    for (final (name, seed) in [
      ('eight_box', _eightBox),
      ('sm2', _sm2),
      ('only_new', _onlyNew),
      ('nothing', _nothing),
    ]) {
      libraryTest('study entry, $name, $theme', (tester, env) async {
        final deckId = await seed(env);
        await withRealShadows(() async {
          await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
          await expectBoundaryGolden(
            tester,
            'goldens/study_entry_${name}_$theme.png',
          );
        });
      });
    }

    libraryTest('study entry, loading, $theme', (tester, env) async {
      final root = await env.decks.root('TOPIK I');
      final pending = StreamController<Never>();
      addTearDown(pending.close);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(root.id),
          brightness,
          overrides: [
            studyEntryProvider(root.id).overrideWith((_) => pending.stream),
          ],
        );
        await expectBoundaryGolden(
          tester,
          'goldens/study_entry_loading_$theme.png',
        );
      });
    });
  }
}
