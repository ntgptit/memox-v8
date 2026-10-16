import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_tile_signs_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

DeckTile _tile({required int subDecks, required int cards}) => DeckTile(
  id: 'd',
  name: 'Korean',
  siblingPosition: 0,
  createdAt: libraryToday,
  schedulerType: SchedulerType.eightBox,
  subDeckCount: subDecks,
  cardCount: cards,
  newCount: 0,
  overdueCount: 0,
  dueTodayCount: 0,
  masteredCount: 0,
  oldestDueAt: null,
  startOfToday: libraryToday,
);

// Screen 01's structure line wraps only between whole terms (The Wrap Rule;
// owner, Q-P6-4): "1248 cards" never splits from its number.
void main() {
  test('sub-decks and cards: two whole terms', () {
    expect(
      deckTileMeta(_tile(subDecks: 4, cards: 1248), _en),
      '4\u00A0sub-decks\u00A0· 1248\u00A0cards',
    );
  });

  test('a deck of cards: one whole term', () {
    expect(deckTileMeta(_tile(subDecks: 0, cards: 420), _en), '420\u00A0cards');
  });
}
