@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// Screens 19 and 20 (FE-A6 P4), against the kit's frames. A Recall screen is
// never pumped with pumpAndSettle: its clock would run out.

final _en = lookupAppLocalizations(const Locale('en'));

/// The kit's cards: `reservation` is asked first, with its long meaning.
const _cards = [
  (
    'reservation',
    'sự đặt chỗ trước — booking a table, seat or room in advance.',
    'Đồng nghĩa: booking',
  ),
  ('waiter', 'người phục vụ', null),
  ('bill', 'hóa đơn', null),
  ('menu', 'thực đơn', null),
  ('tip', 'tiền boa', null),
];

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

/// "Nhà hàng": five due cards with examples, reviewed in [mode].
Future<String> _review(LibraryEnv env, StudyMode mode) async {
  final root = await env.decks.root('Tiếng Anh giao tiếp');
  final leaf = await env.decks.sub(root.id, 'Nhà hàng');
  for (final (index, (front, back, hint)) in _cards.indexed) {
    await insertCard(
      env.db,
      id: 'c$index',
      deckId: leaf.id,
      front: front,
      back: back,
      example: 'I made a $front.',
      hint: hint,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 10 + index),
      box: 2,
    );
  }
  await lockScheduler(env.db, root.id);
  final opened = await studyEntryRepository(
    env.db,
    env.clock.now,
  ).openReviewSession(deckId: leaf.id, mode: mode);
  return (opened as Ok<String, StudyRejection>).value;
}

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
  // Past the faces' fade.
  await tester.pump(AppDurations.standard);
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      StudyMode mode,
      String name,
      Future<void> Function() act, {
      double textScale = 1,
    }) async {
      final id = await _review(env, mode);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(id),
          brightness,
          textScale: textScale,
        );
        await _frames(tester);
        await act();
        await expectBoundaryGolden(tester, 'goldens/study_${name}_$theme.png');
      });
    }

    libraryTest('recall, counting down, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.recall, 'recall_counting', () async {
        await tester.pump(const Duration(seconds: 6));
      });
    });

    libraryTest('recall, revealed, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.recall, 'recall_revealed', () async {
        await tester.pump(const Duration(seconds: 11));
        await tester.tap(find.text(_en.studyRecallShowMeaning));
        await _frames(tester);
      });
    });

    libraryTest('recall, timed out, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.recall, 'recall_timed_out', () async {
        await tester.pump(const Duration(seconds: 20));
        await tester.pump(const Duration(milliseconds: 16));
        await _frames(tester);
      });
    });

    libraryTest('recall, large text, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.recall, 'recall_large_text', () async {
        await tester.tap(find.text(_en.studyRecallShowMeaning));
        await _frames(tester);
      }, textScale: 2);
    });

    libraryTest('fill, input, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.fill, 'fill_input', () async {
        await tester.enterText(find.byType(TextField), 'reserv');
        await tester.pump();
      });
    });

    libraryTest('fill, hint, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.fill, 'fill_hint', () async {
        await tester.enterText(find.byType(TextField), 'reserv');
        await tester.tap(find.text(_en.studyFillShowHint));
        await _frames(tester);
      });
    });

    libraryTest('fill, wrong, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.fill, 'fill_wrong', () async {
        await tester.enterText(find.byType(TextField), 'reservetion');
        await tester.pump();
        await tester.tap(find.text(_en.studyFillCheck));
        await _frames(tester);
      });
    });

    libraryTest('fill, large text, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.fill, 'fill_large_text', () async {
        await tester.enterText(find.byType(TextField), 'reserv');
        await tester.pump();
      }, textScale: 2);
    });
  }
}
