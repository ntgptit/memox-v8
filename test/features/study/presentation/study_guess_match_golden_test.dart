@Tags(['golden'])
library;

import 'package:flutter/material.dart';

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/support/study_choice_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// Screens 18 and 17 (FE-A6 P3), against the kit's default frames.

const _cards = [
  ('reservation', 'đặt chỗ trước'),
  ('waiter', 'người phục vụ'),
  ('bill', 'hóa đơn'),
  ('menu', 'thực đơn'),
  ('tip', 'tiền boa'),
];

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

/// "Nhà hàng": five due cards; `reservation` is asked first.
Future<String> _review(LibraryEnv env, StudyMode mode) async {
  final root = await env.decks.root('Tiếng Anh giao tiếp');
  final leaf = await env.decks.sub(root.id, 'Nhà hàng');
  for (final (index, (front, back)) in _cards.indexed) {
    await insertCard(
      env.db,
      id: 'c$index',
      deckId: leaf.id,
      front: front,
      back: back,
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

/// The painted colour of the tile showing [text], read from the captured
/// pixels: a point 8 dp inside the tile's left edge, on its vertical middle,
/// where no text or icon sits. A press layer still fading over the tile
/// would tint it, so this pins the rest state a golden is meant to show.
Future<Color> _tileColor(WidgetTester tester, String text) async {
  final tile = find.ancestor(
    of: find.text(text),
    matching: find.byType(StudyChoiceWidget),
  );
  final rect = tester.getRect(tile);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(goldenBoundaryKey),
  );
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final data = (await tester.runAsync(
    () => image.toByteData(format: ImageByteFormat.rawRgba),
  ))!;
  final x = (rect.left + 8).round();
  final y = rect.center.dy.round();
  final i = (y * image.width + x) * 4;
  final color = Color.fromARGB(
    data.getUint8(i + 3),
    data.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
  image.dispose();
  return color;
}

/// [actual] has [expected]'s exact RGB, whatever the alpha channel says.
void _expectFill(Color actual, Color expected, String what) {
  expect(
    actual.toARGB32() & 0xFFFFFF,
    expected.toARGB32() & 0xFFFFFF,
    reason:
        '$what: painted #${(actual.toARGB32() & 0xFFFFFF).toRadixString(16)}, '
        'the rest state is #${(expected.toARGB32() & 0xFFFFFF).toRadixString(16)}',
  );
}

Future<void> _golden(WidgetTester tester, String name, String theme) =>
    expectBoundaryGolden(tester, 'goldens/study_${name}_$theme.png');

/// The press layer of a tapped tile (MxRowInk's InkWell highlight and splash)
/// fades out within this; a golden shows the rest state after it.
const Duration _pressLayerFade = Duration(milliseconds: 1000);

/// [screen] under a theme without the ink splash. A wrong pair is shown for
/// 600 ms and the splash of the tap that made it outlasts that, so its
/// press layer would veil the tone in every capture inside the flash; the
/// rest state is the tone alone. Test-only: the app keeps its splash.
Widget _withoutSplash(Widget screen) => Builder(
  builder: (context) => Theme(
    data: Theme.of(context).copyWith(splashFactory: NoSplash.splashFactory),
    child: screen,
  ),
);

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      StudyMode mode,
      String name,
      Future<void> Function() act, {
      bool withoutSplash = false,
    }) async {
      final id = await _review(env, mode);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          withoutSplash ? _withoutSplash(_screen(id)) : _screen(id),
          brightness,
        );
        await tester.pumpAndSettle();
        await act();
        await _golden(tester, name, theme);
      });
      // Let a held turn's timer run out before the tree goes.
      await tester.pump(const Duration(milliseconds: 1500));
    }

    Future<void> pick(WidgetTester tester, String meaning) async {
      await tester.tap(find.text(meaning));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    libraryTest('guess, idle, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.guess, 'guess_idle', () async {});
    });

    libraryTest('guess, wrong, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        StudyMode.guess,
        'guess_wrong',
        () => pick(tester, 'hóa đơn'),
      );
    });

    libraryTest('guess, right, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        StudyMode.guess,
        'guess_right',
        () => pick(tester, 'đặt chỗ trước'),
      );
    });

    testWidgets('guess, blocked, $theme', (tester) async {
      final env = LibraryEnv(
        openTestDatabase(interceptor: ThinMeaningSource(4)),
        FakeDayClock(libraryToday),
      );
      try {
        // The seed the backend's blocked-question test proves (BR-STUDY-040).
        final id = await openFiveDueReview(
          env.db,
          env.decks,
          libraryToday,
          StudyMode.guess,
        );
        await withRealShadows(() async {
          await pumpLibraryGolden(tester, env, _screen(id), brightness);
          await tester.pumpAndSettle();
          await _golden(tester, 'guess_blocked', theme);
        });
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
        await env.db.close();
      }
    });

    libraryTest('match, board, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.match, 'match_board', () async {
        await tester.tap(find.text('reservation'));
        await tester.pump();
        await tester.tap(find.text('đặt chỗ trước'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('waiter'));
        await tester.pump();
        // The tone eases in.
        await tester.pump(AppDurations.standard);
        await tester.pump(_pressLayerFade);
        final scheme = Theme.of(
          tester.element(find.byType(StudyChoiceWidget).first),
        ).colorScheme;
        _expectFill(
          await _tileColor(tester, 'waiter'),
          scheme.primary,
          'the selected tile',
        );
      });
    });

    libraryTest('match, wrong, $theme', (tester, env) async {
      await shoot(tester, env, StudyMode.match, 'match_wrong', () async {
        await tester.tap(find.text('reservation'));
        await tester.pump();
        await tester.tap(find.text('hóa đơn'));
        await tester.pump();
        await tester.pump();
        // Past the tone's ease, inside the 600 ms flash.
        await tester.pump(const Duration(milliseconds: 300));
        final scheme = Theme.of(
          tester.element(find.byType(StudyChoiceWidget).first),
        ).colorScheme;
        for (final text in ['reservation', 'hóa đơn']) {
          _expectFill(
            await _tileColor(tester, text),
            scheme.errorContainer,
            'the wrong tile $text',
          );
        }
      }, withoutSplash: true);
    });
  }
}
