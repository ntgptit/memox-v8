import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';

// BR-PROGRESS-001, BR-PROGRESS-003, BR-PROGRESS-005, BR-PROGRESS-006: one
// level of Progress by deck (Progress spec §5.2, §5.4).

const _none = ProgressNumbers(
  activeCards: 0,
  activeDays: 0,
  learningCardDays: 0,
  reviewingCardDays: 0,
);

ProgressNumbers _active(int cards) => ProgressNumbers(
  activeCards: cards,
  activeDays: 1,
  learningCardDays: 0,
  reviewingCardDays: cards,
);

ProgressDeckRow _deck(String id, String name, {int week = 0, int month = 0}) =>
    ProgressDeckRow(
      deckId: id,
      name: name,
      progress: RangeProgress(
        week: week == 0 ? _none : _active(week),
        month: month == 0 ? _none : _active(month),
      ),
    );

ProgressLevel _level(List<ProgressDeckRow> decks) => ProgressLevel(
  total: const RangeProgress(week: _none, month: _none),
  decks: decks,
);

List<String> _ids(List<ProgressDeckRow> decks) => [
  for (final deck in decks) deck.deckId,
];

void main() {
  test('each range orders the decks by its own active cards, most first '
      '(BR-PROGRESS-006)', () {
    final level = _level([
      _deck('a', 'Alpha', week: 1, month: 9),
      _deck('b', 'Beta', week: 5, month: 2),
    ]);

    expect(_ids(level.decksFor(ProgressRange.week)), ['b', 'a']);
    expect(_ids(level.decksFor(ProgressRange.month)), ['a', 'b']);
  });

  test('a tie falls to the name folded in Dart, so Động and động sit '
      'together as Verbs and verbs do, then to the id (BR-PROGRESS-006)', () {
    final level = _level([
      _deck('3', 'động'),
      _deck('1', 'Zebra'),
      _deck('2', 'Động'),
      _deck('0', 'verbs'),
      _deck('4', 'Verbs'),
    ]);

    expect(_ids(level.decksFor(ProgressRange.week)), ['0', '4', '1', '2', '3']);
  });

  test('a deck with no activity stays in the list, after every active one, '
      'in an order that does not change from read to read '
      '(BR-PROGRESS-006)', () {
    final decks = [
      _deck('c', 'Charlie'),
      _deck('z', 'Zulu', week: 1, month: 1),
      _deck('a', 'Alpha'),
      _deck('b', 'Bravo'),
    ];

    final first = _level(decks).decksFor(ProgressRange.week);
    final second = _level(decks.reversed.toList()).decksFor(ProgressRange.week);

    expect(_ids(first), ['z', 'a', 'b', 'c']);
    expect(_ids(second), _ids(first));
  });

  test('a range reads its own numbers; card-days are Learning and Reviewing '
      'together (BR-PROGRESS-001, BR-PROGRESS-003, BR-PROGRESS-005)', () {
    const week = ProgressNumbers(
      activeCards: 3,
      activeDays: 2,
      learningCardDays: 1,
      reviewingCardDays: 4,
    );
    const progress = RangeProgress(week: week, month: _none);

    expect(progress.of(ProgressRange.week), same(week));
    expect(progress.of(ProgressRange.month), same(_none));
    expect(week.cardDays, 5);
    expect(week.hasActivity, isTrue);
    expect(_none.hasActivity, isFalse);
  });

  test('a level with no deck has no row (UC-PROGRESS-002 A2)', () {
    expect(_level([]).hasDecks, isFalse);
    expect(_level([_deck('a', 'Alpha')]).hasDecks, isTrue);
  });
}
