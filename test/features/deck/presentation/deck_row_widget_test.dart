import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_row_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _today = DateTime(2026, 9, 24);

DeckTile _tile({
  String name = 'Korean',
  int subDecks = 4,
  int cards = 1248,
  int overdue = 41,
  int today = 45,
}) => DeckTile(
  id: 'k',
  name: name,
  siblingPosition: 0,
  createdAt: _today,
  schedulerType: SchedulerType.sm2,
  subDeckCount: subDecks,
  cardCount: cards,
  newCount: 0,
  overdueCount: overdue,
  dueTodayCount: today,
  oldestDueAt: overdue > 0 ? DateTime(2026, 9, 20) : null,
  startOfToday: _today,
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    LibraryEnv env,
    DeckTile tile, {
    VoidCallback? onMore,
    double textScale = 1,
  }) => pumpLibraryScreen(
    tester,
    env,
    Scaffold(
      body: Center(
        child: DeckRowWidget(tile: tile, onTap: () {}, onMore: onMore ?? () {}),
      ),
    ),
    textScale: textScale,
  );

  libraryTest('a card with the name, the due badge and the structure line', (
    tester,
    env,
  ) async {
    await pump(tester, env, _tile());

    expect(find.byType(MxCard), findsOneWidget);
    expect(find.text('Korean'), findsOneWidget);
    expect(find.widgetWithText(MxBadge, _en.deckDueBadge(86)), findsOneWidget);
    expect(
      find.text(
        _en.deckRowMeta(_en.deckSubDeckCount(4), _en.deckCardCount(1248)),
      ),
      findsOneWidget,
    );
  });

  libraryTest('no badge when nothing is due; an empty deck says so', (
    tester,
    env,
  ) async {
    await pump(tester, env, _tile(subDecks: 0, cards: 0, overdue: 0, today: 0));

    expect(find.byType(MxBadge), findsNothing);
    expect(find.text(_en.deckRowEmpty), findsOneWidget);
  });

  libraryTest('⋮ is its own button, named for the deck', (tester, env) async {
    var more = 0;
    await pump(tester, env, _tile(), onMore: () => more++);

    await tester.tap(find.byTooltip(_en.deckMoreActions('Korean')));
    expect(more, 1);
  });

  libraryTest('a long name at text scale 2 on a 360 phone does not overflow', (
    tester,
    env,
  ) async {
    await pump(
      tester,
      env,
      _tile(name: 'Thuật ngữ Kinh tế – Tài chính – Ngân hàng cho kỳ thi'),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
}
