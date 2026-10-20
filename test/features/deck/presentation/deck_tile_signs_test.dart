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

// Screen 01's structure line: a line of terms the row lays out whole (The
// Wrap Rule, spec W1).
void main() {
  test('sub-decks and cards: two terms', () {
    expect(
      deckTileMeta(_tile(subDecks: 4, cards: 1248), _en),
      '4 sub-decks · 1248 cards',
    );
  });

  test('a deck of cards: one term', () {
    expect(deckTileMeta(_tile(subDecks: 0, cards: 420), _en), '420 cards');
  });

  // MxTermLine splits at " · ": a translation that joined the two counts any
  // other way would make the whole line one term.
  test('every language joins the two counts with " · "', () {
    for (final locale in AppLocalizations.supportedLocales) {
      expect(
        lookupAppLocalizations(locale).deckRowMeta('A', 'B'),
        'A · B',
        reason: '$locale',
      );
    }
  });
}
