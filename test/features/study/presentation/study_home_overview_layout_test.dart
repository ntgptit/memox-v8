import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_decks_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_workload_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';

// Screen 13 is the overview of "Flashcard Color Tokens" §5: one column, two
// once its content area holds two 300 columns and the 24 gap, measured with
// a LayoutBuilder; its cards take the overview's 16 interior (§4.1).

StudyHomeScreen _screen() => StudyHomeScreen(
  onOpenSession: (_) {},
  onOpenDeck: (_) {},
  onOpenLibrary: () {},
  onOpenStarterDecks: () {},
  onOpenSync: () {},
);

Future<void> _seed(LibraryEnv env) async {
  await openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.recall);
  final root = await env.decks.root('Spanish');
  final leaf = await env.decks.sub(root.id, 'Leaf');
  await insertCard(env.db, id: 's-1', deckId: leaf.id, back: 'uno');
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _resize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  await _settle(tester);
}

void main() {
  libraryTest('on a phone the workload and the decks stack in one column', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, _screen());
    await _settle(tester);

    final workload = tester.getRect(find.byType(StudyHomeWorkloadWidget));
    final decks = tester.getRect(find.byType(StudyHomeDecksWidget));
    expect(decks.top, greaterThan(workload.bottom));
    expect(decks.left, workload.left);
    // A deck list's 64 tile (§4.3; owner 2026-10-13).
    final tile = tester.widget<MxIconTile>(
      find
          .descendant(
            of: find.byType(StudyHomeDecksWidget),
            matching: find.byType(MxIconTile),
          )
          .first,
    );
    expect(tile.size, MxIconTileSize.deck);
    expect(tile.tone, MxIconTileTone.deck);
  });

  libraryTest('from a 672 content area the decks sit beside the workload, '
      'each column at least 300 with the 24 gap', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, _screen());
    await _resize(tester, 672);

    // The lead column holds the Resume card over the workload.
    final resume = tester.getRect(find.byType(StudyHomeResumeWidget));
    final workload = tester.getRect(find.byType(StudyHomeWorkloadWidget));
    final decks = tester.getRect(find.byType(StudyHomeDecksWidget));
    expect(workload.top, greaterThan(resume.bottom));
    expect(decks.top, resume.top);
    expect(decks.left - workload.right, AppSpacing.section);
    expect(workload.width, greaterThanOrEqualTo(AppSize.overviewColumnMin));
    expect(decks.width, greaterThanOrEqualTo(AppSize.overviewColumnMin));
  });

  libraryTest('just under 672 it keeps one column', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, _screen());
    await _resize(tester, 671);

    final workload = tester.getRect(find.byType(StudyHomeWorkloadWidget));
    final decks = tester.getRect(find.byType(StudyHomeDecksWidget));
    expect(decks.top, greaterThan(workload.bottom));
  });

  libraryTest('the overview cards take the compact interior', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, _screen());
    await _settle(tester);

    final cards = tester.widgetList<MxCard>(find.byType(MxCard));
    expect(cards, isNotEmpty);
    for (final card in cards) {
      expect(card.isCompact, isTrue);
    }
  });
}
