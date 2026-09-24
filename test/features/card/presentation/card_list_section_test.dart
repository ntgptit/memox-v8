import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/providers/card_list_provider.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _section(String deckId) =>
    Scaffold(body: CardListSectionWidget(deckId: deckId));

/// Korean › Words: annyeong (new), gamsa (due today), sarang (due
/// tomorrow) and mul (new, flagged).
Future<String> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await insertCard(
    env.db,
    id: 'new1',
    deckId: words.id,
    front: 'annyeong',
    back: 'hello',
  );
  await insertCard(
    env.db,
    id: 'due1',
    deckId: words.id,
    front: 'gamsa',
    back: 'thanks',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
  );
  await insertCard(
    env.db,
    id: 'later',
    deckId: words.id,
    front: 'sarang',
    back: 'love',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 25),
  );
  await insertCard(
    env.db,
    id: 'flag1',
    deckId: words.id,
    front: 'mul',
    back: 'water',
    isFlagged: true,
  );
  return words.id;
}

int? _chipCount(WidgetTester tester, String label) =>
    tester.widget<MxFilterChip>(find.widgetWithText(MxFilterChip, label)).count;

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(MxFilterChip, label));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('rows show front, back, a status dot and the flag', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));

    expect(find.text('annyeong'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.byType(CardRowWidget), findsNWidgets(4));
    expect(find.byType(MxStatusBadge), findsNWidgets(4));
    expect(find.byIcon(AppIcons.flagged), findsOneWidget);
  });

  libraryTest('each chip counts its filter; a chip filters the rows', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));

    expect(
      [
        for (final label in [
          _en.cardFilterAll,
          _en.cardFilterDue,
          _en.cardFilterNew,
          _en.cardFilterFlagged,
        ])
          _chipCount(tester, label),
      ],
      [4, 1, 2, 1],
    );
    await _tapChip(tester, _en.cardFilterFlagged);

    expect(find.byType(CardRowWidget), findsOneWidget);
    expect(find.text('mul'), findsOneWidget);
  });

  libraryTest('search matches the front or the back', (tester, env) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.enterText(find.byType(EditableText), 'thank');
    await tester.pumpAndSettle();

    expect(find.byType(CardRowWidget), findsOneWidget);
    expect(find.text('gamsa'), findsOneWidget);
  });

  libraryTest('due first puts the soonest due first and new cards last', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.tap(find.text(_en.cardSortTrigger(_en.cardSortNewest)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardSortDueFirst));
    await tester.pumpAndSettle();

    double top(String front) => tester.getTopLeft(find.text(front)).dy;
    expect(top('gamsa'), lessThan(top('sarang')));
    expect(top('sarang'), lessThan(top('annyeong')));
  });

  libraryTest('midnight brings the next day\'s card into Due (RF3)', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    env.clock.startDay(DateTime(2026, 9, 25));
    await tester.pump();
    await tester.pump();

    expect(_chipCount(tester, _en.cardFilterDue), 2);
  });

  libraryTest('an empty filter names itself and offers every card', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
    await pumpLibraryScreen(tester, env, _section(words.id));
    await _tapChip(tester, _en.cardFilterFlagged);

    expect(
      find.text(_en.cardFilterEmptyTitle(_en.cardFilterFlagged)),
      findsOneWidget,
    );
    await tester.tap(find.text(_en.cardShowAll));
    await tester.pumpAndSettle();
    expect(find.text('annyeong'), findsOneWidget);
  });

  libraryTest('a search with no hit names the term', (tester, env) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text(_en.cardSearchEmptyTitle('zzz')), findsOneWidget);
  });

  libraryTest('the window grows near the end and keeps its rows (RF4)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    for (var i = 0; i < 60; i++) {
      await insertCard(
        env.db,
        id: 'c${i.toString().padLeft(2, '0')}',
        deckId: words.id,
        front: 'card $i',
      );
    }
    await pumpLibraryScreen(tester, env, _section(words.id));
    expect(find.byType(CardRowWidget), findsNWidgets(cardListWindowStep));

    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pump();
    expect(find.byType(MxSkeletonRow), findsNothing);
    expect(
      find.byType(CardRowWidget),
      findsAtLeastNWidgets(cardListWindowStep),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CardRowWidget), findsNWidgets(60));
  });

  libraryTest('a load error says so plainly and offers Retry', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      _section(deckId),
      overrides: [
        cardListProvider(
          deckId: deckId,
          filter: CardListFilter.all,
          sort: CardListSort.newest,
          searchTerm: '',
          windowSize: cardListWindowStep,
        ).overrideWith(
          (ref) => Stream<CardListView>.error(StateError('disk I/O error')),
        ),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.textContaining('disk'), findsNothing);
  });

  libraryTest('long cards at 2x meet the target guidelines', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(
      env.db,
      id: 'long',
      deckId: words.id,
      front: List.filled(6, '한국어 단어').join(' '),
      back: List.filled(20, 'nghĩa tiếng Việt').join(' '),
      isFlagged: true,
    );
    await pumpLibraryScreen(tester, env, _section(words.id), textScale: 2);

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
