import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/providers/card_detail_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_content_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_schedule_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// [build] over the card as the detail reads it, through the provider the
/// screen watches.
Widget _host(String cardId, List<Widget> Function(CardDetail detail) build) =>
    Scaffold(
      body: Consumer(
        builder: (context, ref, _) =>
            switch (ref.watch(cardDetailProvider(cardId))) {
              AsyncData(value: Ok(:final value)) => ListView(
                children: build(value),
              ),
              _ => const SizedBox.shrink(),
            },
      ),
    );

Future<String> _words(
  LibraryEnv env, [
  SchedulerType type = SchedulerType.eightBox,
]) async {
  final korean = await env.decks.root('Korean', type);
  return (await env.decks.sub(korean.id, 'Words')).id;
}

void main() {
  libraryTest(
    'the content shows only the fields that have a value (BR-CARD-014)',
    (tester, env) async {
      final deckId = await _words(env);
      final card = await env.cards.card(
        deckId,
        const CardDraft(
          front: 'bap',
          back: 'rice',
          example: 'Bap meogeosseoyo?',
          isFlagged: true,
          tagNames: ['food'],
        ),
      );
      await pumpLibraryScreen(
        tester,
        env,
        _host(card.id, (detail) => [CardDetailContentWidget(detail: detail)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('bap'), findsOneWidget);
      expect(find.text('rice'), findsOneWidget);
      expect(find.text('Bap meogeosseoyo?'), findsOneWidget);
      expect(find.text(_en.cardFieldExample.toUpperCase()), findsOneWidget);
      expect(find.text(_en.cardFieldHint.toUpperCase()), findsNothing);
      expect(find.text('food'), findsOneWidget);
      expect(find.bySemanticsLabel(_en.cardFlaggedLabel), findsOneWidget);
      expect(find.text(_en.cardStatusNew), findsOneWidget);
    },
  );

  libraryTest('an eight-box card shows its box on the ramp and its facts', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await insertCard(
      env.db,
      id: 'c',
      deckId: deckId,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 28),
      box: 3,
    );
    await pumpLibraryScreen(
      tester,
      env,
      _host('c', (detail) => [CardScheduleWidget(detail: detail)]),
    );
    await tester.pumpAndSettle();

    expect(find.text(_en.cardScheduleBox(3, 8).toUpperCase()), findsOneWidget);
    expect(find.text(_en.cardBoxRampStart), findsOneWidget);
    expect(
      find.text(DateFormat.yMMMd('en').format(DateTime(2026, 9, 28))),
      findsOneWidget,
    );
    expect(find.textContaining(_en.cardSchedulerEightBox), findsOneWidget);
    expect(find.text(_en.cardFactEase), findsNothing);
  });

  libraryTest('an SM-2 card shows ease, interval and repetitions, no ramp', (
    tester,
    env,
  ) async {
    final deckId = await _words(env, SchedulerType.sm2);
    await insertCard(
      env.db,
      id: 'c',
      deckId: deckId,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 28),
      intervalDays: 6,
    );
    await pumpLibraryScreen(
      tester,
      env,
      _host('c', (detail) => [CardScheduleWidget(detail: detail)]),
    );
    await tester.pumpAndSettle();

    expect(find.text(_en.cardScheduleSm2.toUpperCase()), findsOneWidget);
    expect(find.text(_en.cardBoxRampStart), findsNothing);
    expect(find.text('2.50'), findsOneWidget);
    expect(find.text(_en.cardFactIntervalValue(6)), findsOneWidget);
    expect(find.text(_en.cardFactRepetitions), findsOneWidget);
  });

  libraryTest('a new card says what has not happened yet', (tester, env) async {
    final deckId = await _words(env);
    await insertCard(env.db, id: 'c', deckId: deckId);
    await pumpLibraryScreen(
      tester,
      env,
      _host('c', (detail) => [CardScheduleWidget(detail: detail)]),
    );
    await tester.pumpAndSettle();

    // Due, learned and last answered.
    expect(find.text(_en.cardFactNotYet), findsNWidgets(3));
  });

  libraryTest('content and schedule hold at 2x and meet the guidelines', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(
        front: 'Tiếng Việt có dấu, một thuật ngữ khá dài',
        back: 'a long meaning that wraps over several lines at 2x',
        pronunciation: 'tiếng việt',
        tagNames: ['từ vựng', 'topik 1'],
      ),
    );
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        card.id,
        (detail) => [
          CardDetailContentWidget(detail: detail),
          CardScheduleWidget(detail: detail),
        ],
      ),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
