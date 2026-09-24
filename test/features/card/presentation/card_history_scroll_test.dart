import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:memox/features/card/presentation/providers/load_card_history_page_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_history_scroll_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _addedAt = DateTime(2026, 8, 1);

Widget _section() => Scaffold(
  body: CardHistoryScrollWidget(
    cardId: 'c',
    addedAt: _addedAt,
    leading: const [],
  ),
);

/// When the answer logged [minutes] after the first was given, as the
/// history shows it.
String _at(int minutes) =>
    DateFormat.MMMd('en')
        .add_Hm()
        .format(DateTime(2026, 9, 1, 8).add(Duration(minutes: minutes)));

Finder get _scrollable => find.byType(Scrollable).first;

/// Korean › Words holding card `c`.
Future<void> _card(LibraryEnv env) async {
  final words = await env.decks.sub(
    (await env.decks.root('Korean')).id,
    'Words',
  );
  await insertCard(env.db, id: 'c', deckId: words.id);
}

Future<void> _answers(LibraryEnv env, int count) async {
  for (var i = 0; i < count; i++) {
    await logReview(
      env.db,
      id: 'r$i',
      cardId: 'c',
      at: DateTime(2026, 9, 1, 8).add(Duration(minutes: i)),
    );
  }
}

/// Fails the first older page, then answers as [_cards] does.
final class _FlakyHistory implements CardRepository {
  _FlakyHistory(this._cards);

  final CardRepository _cards;
  var _hasFailed = false;

  @override
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  }) async {
    if (after != null && !_hasFailed) {
      _hasFailed = true;
      throw const UnknownDatabaseFailure(cause: '/data/memox.sqlite');
    }
    return _cards.historyPage(cardId: cardId, after: after);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Scrolls to the end-of-history line, which follows the oldest answer.
Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text(_en.cardHistoryEnd(DateFormat.yMMMd('en').format(_addedAt))),
    500,
    scrollable: _scrollable,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapLoadMore(WidgetTester tester, String label) async {
  final button = find.widgetWithText(MxButton, label);
  await tester.scrollUntilVisible(button, 500, scrollable: _scrollable);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('a card never studied says so (BR-CARD-018)', (
    tester,
    env,
  ) async {
    await _card(env);
    await pumpLibraryScreen(tester, env, _section());
    await tester.pumpAndSettle();

    expect(find.text(_en.cardHistory.toUpperCase()), findsOneWidget);
    expect(find.text(_en.cardHistoryEmptyTitle), findsOneWidget);
  });

  libraryTest('each answer shows the values its row stored (BR-CARD-016)', (
    tester,
    env,
  ) async {
    await _card(env);
    await logReview(
      env.db,
      id: 'a',
      cardId: 'c',
      at: DateTime(2026, 9, 2, 8),
      mode: 'fill',
      usedHint: true,
      previousBox: 2,
      nextBox: 3,
      nextDueAt: DateTime(2026, 9, 6),
    );
    await logReview(
      env.db,
      id: 'b',
      cardId: 'c',
      at: DateTime(2026, 9, 3, 8),
      kind: 'learning',
      action: 'forgotten',
      isTimedOut: true,
    );
    await pumpLibraryScreen(tester, env, _section());
    await tester.pumpAndSettle();

    expect(find.text(_en.cardHistoryNewestFirst.toUpperCase()), findsOneWidget);
    for (final label in [
      _en.cardHistoryKindScheduled,
      _en.cardActionRemembered,
      _en.cardHistoryKindLearning,
      _en.cardActionForgotten,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text(_en.cardModeFill), findsOneWidget);
    // The mode carries the Study glyph, not the Library's.
    expect(
      find.descendant(
        of: find.byType(CardHistoryEventWidget),
        matching: find.byIcon(AppIcons.study),
      ),
      findsNWidgets(2),
    );
    expect(find.byIcon(AppIcons.library), findsNothing);
    expect(find.text(_en.cardHistoryBoxMove(2, 3)), findsOneWidget);
    expect(find.text(_en.cardHistoryHintUsed), findsOneWidget);
    expect(find.text(_en.cardHistoryTimedOut), findsOneWidget);
    expect(
      find.text(
        _en.cardHistoryNextDue(
          DateFormat.MMMd('en').format(DateTime(2026, 9, 6)),
        ),
      ),
      findsOneWidget,
    );
  });

  libraryTest('answers group by cycle, the current one first (BR-CARD-017)', (
    tester,
    env,
  ) async {
    await _card(env);
    await logReview(
      env.db,
      id: 'new',
      cardId: 'c',
      at: DateTime(2026, 9, 2, 8),
      generation: 2,
    );
    await logReview(
      env.db,
      id: 'old',
      cardId: 'c',
      at: DateTime(2026, 4, 6, 20),
      schedulerType: 'sm2',
      mode: 'self_assess',
      action: 'hard',
      previousEase: 2.5,
      nextEase: 2.36,
      previousInterval: 1,
      nextInterval: 6,
    );
    await pumpLibraryScreen(tester, env, _section());
    await tester.pumpAndSettle();

    final current = find.text(
      _en.cardHistoryCycle(2, _en.cardSchedulerEightBox).toUpperCase(),
    );
    final earlier = find.text(
      _en.cardHistoryCycle(1, _en.cardSchedulerSm2).toUpperCase(),
    );
    expect(current, findsOneWidget);
    expect(earlier, findsOneWidget);
    expect(
      tester.getTopLeft(current).dy,
      lessThan(tester.getTopLeft(earlier).dy),
    );
    expect(find.text(_en.cardHistoryEaseMove('2.50', '2.36')), findsOneWidget);
    expect(find.text(_en.cardHistoryIntervalMove(1, 6)), findsOneWidget);
    expect(find.text(_en.cardModeSelfAssess), findsOneWidget);
  });

  libraryTest('Load older history adds the rest, then the history ends (A5)', (
    tester,
    env,
  ) async {
    await _card(env);
    await _answers(env, ReviewHistoryPage.size + 1);
    await pumpLibraryScreen(tester, env, _section());
    await tester.pumpAndSettle();
    // The oldest answer is on the second page.
    expect(find.text(_at(0), skipOffstage: false), findsNothing);

    await _tapLoadMore(tester, _en.cardHistoryLoadMore);
    await _scrollToEnd(tester);

    expect(find.text(_at(0)), findsOneWidget);
    expect(
      find.widgetWithText(
        MxButton,
        _en.cardHistoryLoadMore,
        skipOffstage: false,
      ),
      findsNothing,
    );
  });

  libraryTest('a failed older page keeps the rows and offers Retry (E4)', (
    tester,
    env,
  ) async {
    await _card(env);
    await _answers(env, ReviewHistoryPage.size + 1);
    await pumpLibraryScreen(
      tester,
      env,
      _section(),
      overrides: [
        loadCardHistoryPageUseCaseProvider.overrideWithValue(
          LoadCardHistoryPageUseCase(_FlakyHistory(env.cards)),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await _tapLoadMore(tester, _en.cardHistoryLoadMore);

    expect(find.text(_en.cardHistoryLoadMoreFailedTitle), findsOneWidget);
    expect(find.text(_at(1)), findsOneWidget);
    expect(find.text(_at(0), skipOffstage: false), findsNothing);
    expect(find.textContaining('sqlite'), findsNothing);

    await _tapLoadMore(tester, _en.commonRetry);
    await _scrollToEnd(tester);
    expect(find.text(_at(0)), findsOneWidget);
    expect(
      find.text(_en.cardHistoryLoadMoreFailedTitle, skipOffstage: false),
      findsNothing,
    );
  });

  libraryTest('the history holds at 2x and meets the guidelines', (
    tester,
    env,
  ) async {
    await _card(env);
    await logReview(
      env.db,
      id: 'a',
      cardId: 'c',
      at: DateTime(2026, 9, 2, 8),
      mode: 'fill',
      usedHint: true,
      previousBox: 2,
      nextBox: 3,
      nextDueAt: DateTime(2026, 9, 6),
    );
    await pumpLibraryScreen(tester, env, _section(), textScale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });

  libraryTest('only the answers in view are built', (tester, env) async {
    await _card(env);
    await _answers(env, ReviewHistoryPage.size);
    await pumpLibraryScreen(tester, env, _section());
    await tester.pumpAndSettle();

    expect(
      find
          .byType(CardHistoryEventWidget, skipOffstage: false)
          .evaluate()
          .length,
      lessThan(ReviewHistoryPage.size),
    );
  });
}
