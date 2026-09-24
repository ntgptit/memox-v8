import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_status_distribution.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Korean › Words: one overdue, one due today, one new, one mastered.
Future<String> _deckWithWork(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await insertCard(
    env.db,
    id: 'late',
    deckId: words.id,
    front: 'late',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 20),
    box: 2,
  );
  await insertCard(
    env.db,
    id: 'today',
    deckId: words.id,
    front: 'today',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
    box: 5,
  );
  await insertCard(env.db, id: 'new', deckId: words.id, front: 'new');
  await insertCard(
    env.db,
    id: 'known',
    deckId: words.id,
    front: 'known',
    learnedAt: DateTime(2026, 5, 1),
    dueAt: DateTime(2026, 12, 1),
    box: 8,
  );
  return words.id;
}

void main() {
  libraryTest('the summary: algorithm, mastered of total, workload, the '
      'distribution, Study disabled', (tester, env) async {
    final deckId = await _deckWithWork(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: deckId));
    await tester.pumpAndSettle();

    expect(
      find.text(
        _en.cardSummaryOverline(_en.cardSchedulerEightBox).toUpperCase(),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.cardSummaryMastered(1, 4)), findsOneWidget);
    expect(
      find.text('1 overdue · 1 today · 1 new', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(MxStatusDistribution), findsOneWidget);
    expect(
      tester.widget<MxMasteryDonut>(find.byType(MxMasteryDonut)).fraction,
      0.25,
    );
    final study = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.cardStudyThisDue(2)),
    );
    expect(study.onPressed, isNull);
  });

  libraryTest('Tags shows, disabled, and says it is not available yet', (
    tester,
    env,
  ) async {
    final deckId = await _deckWithWork(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: deckId));
    await tester.pumpAndSettle();

    final tags = find.widgetWithText(MxFilterChip, _en.cardFilterTags);
    expect(tester.widget<MxFilterChip>(tags).onSelected, isNull);
    expect(
      tester.getSemantics(tags),
      isSemantics(hint: _en.commonNotAvailableYet),
    );
  });

  libraryTest('the header counts what shows and names the sort; selecting '
      'hides the summary', (tester, env) async {
    final deckId = await _deckWithWork(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: deckId));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardListShowing(4, 4).toUpperCase()), findsOneWidget);
    expect(
      find.widgetWithText(MxChipTrigger, _en.cardSortNewestPill),
      findsOneWidget,
    );
    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();

    expect(find.byType(CardDeckSummaryWidget), findsNothing);
    expect(
      find.text(_en.cardListSelectedOf(1, 4).toUpperCase()),
      findsOneWidget,
    );
    expect(find.byType(MxChipTrigger), findsNothing);
  });

  libraryTest('a deck with no mastered card reads 0%', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    for (final id in ['a', 'b', 'c']) {
      await insertCard(env.db, id: id, deckId: words.id);
    }
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MxMasteryDonut>(find.byType(MxMasteryDonut)).fraction,
      0,
    );
    expect(tester.takeException(), isNull);
  });
}
