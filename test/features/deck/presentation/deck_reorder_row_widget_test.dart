import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_reorder_row_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _today = DateTime(2026, 9, 24);

DeckTile _tile({required int subDecks, required int cards}) => DeckTile(
  id: 'k',
  name: 'Korean',
  siblingPosition: 0,
  createdAt: _today,
  schedulerType: SchedulerType.sm2,
  subDeckCount: subDecks,
  cardCount: cards,
  newCount: 0,
  overdueCount: 0,
  dueTodayCount: 0,
  masteredCount: 0,
  oldestDueAt: null,
  startOfToday: _today,
);

// DEV-232 (UI-REV-003), handoff 01 ruling M3-D2: a row in reorder mode keeps
// the browse row's signs for the same deck, the glyph for what it holds and
// the structure line, so a deck does not change meaning when it is dragged.
void main() {
  Future<void> pump(WidgetTester tester, LibraryEnv env, DeckTile tile) =>
      pumpLibraryScreen(
        tester,
        env,
        Scaffold(
          body: Center(child: DeckReorderRowWidget(tile: tile, index: 0)),
        ),
      );

  libraryTest('an empty deck keeps the folder glyph and the empty line', (
    tester,
    env,
  ) async {
    await pump(tester, env, _tile(subDecks: 0, cards: 0));

    expect(find.byIcon(AppIcons.folder), findsOneWidget);
    expect(find.byIcon(AppIcons.library), findsNothing);
    expect(find.text(_en.deckRowEmpty), findsOneWidget);
    expect(find.byIcon(AppIcons.dragHandle), findsOneWidget);
  });

  libraryTest('a deck of decks keeps the layers glyph and its counts', (
    tester,
    env,
  ) async {
    await pump(tester, env, _tile(subDecks: 4, cards: 1248));

    expect(find.byIcon(AppIcons.library), findsOneWidget);
    expect(
      find.text(
        _en.deckRowMeta(_en.deckSubDeckCount(4), _en.deckCardCount(1248)),
      ),
      findsOneWidget,
    );
  });

  libraryTest('a deck of cards keeps the copy glyph and its card count', (
    tester,
    env,
  ) async {
    await pump(tester, env, _tile(subDecks: 0, cards: 420));

    expect(find.byIcon(AppIcons.cardDeck), findsOneWidget);
    expect(find.text(_en.deckCardCount(420)), findsOneWidget);
  });
}
