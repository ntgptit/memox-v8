import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';

// UC-STUDY-002 steps 1–3: the loaded states, the order and the hero of the
// Study tab (Study Home spec §5).

StudyHomeDeck deck(
  String id, {
  String? name,
  int cards = 10,
  int overdue = 0,
  int dueToday = 0,
  int fresh = 0,
}) => StudyHomeDeck(
  deckId: id,
  name: name ?? id,
  schedulerType: SchedulerType.eightBox,
  cardCount: cards,
  overdueCount: overdue,
  dueTodayCount: dueToday,
  newCount: fresh,
);

List<String> idsOf(StudyHomeContent content) => [
  for (final deck in (content as RootDeckWorkload).decks) deck.deckId,
];

void main() {
  test('orders the decks by Overdue, then Due today, then New, never by the '
      'total (BR-STUDY-076)', () {
    final content = studyHomeContentOf([
      deck('big-today', dueToday: 100, fresh: 500),
      deck('new-only', fresh: 3),
      deck('one-overdue', overdue: 1),
      deck('today', dueToday: 5),
      deck('today-and-new', dueToday: 5, fresh: 1),
    ], nextDueAt: null);

    expect(idsOf(content), [
      'one-overdue',
      'big-today',
      'today-and-new',
      'today',
      'new-only',
    ]);
  });

  test('breaks a tie by the Unicode-folded name, then by id '
      '(BR-STUDY-076, BR-TAG-001)', () {
    final content = studyHomeContentOf([
      deck('z', name: 'Zebra'),
      deck('e1', name: 'Émile'),
      deck('k2', name: 'korean'),
      deck('a', name: 'apple'),
      deck('e2', name: 'élan'),
      deck('k1', name: 'Korean'),
    ], nextDueAt: null);

    expect(idsOf(content), ['a', 'k1', 'k2', 'z', 'e2', 'e1']);
  });

  test('no root deck, roots without a card, and cards with no workload are '
      'the three loaded states (BR-STUDY-077, BR-STUDY-008)', () {
    final nextDue = DateTime(2026, 9, 26);

    expect(studyHomeContentOf([], nextDueAt: null), isA<NoRootDecks>());
    expect(
      studyHomeContentOf([
        deck('a', cards: 0),
        deck('b', cards: 0),
      ], nextDueAt: null),
      isA<NoCards>(),
    );
    expect(
      studyHomeContentOf([deck('a'), deck('b', cards: 0)], nextDueAt: nextDue),
      isA<RootDeckWorkload>()
          .having((content) => content.decks, 'decks', hasLength(2))
          .having((content) => content.isCaughtUp, 'caught up', isTrue)
          .having((content) => content.nextDueAt, 'next due', nextDue),
    );
  });

  test('a deck without a card stays in the list, after the decks with work, '
      'and cannot be studied (BR-STUDY-076)', () {
    final content = studyHomeContentOf([
      deck('empty', name: 'A empty', cards: 0),
      deck('rested', name: 'B rested'),
      deck('busy', name: 'C busy', fresh: 2),
    ], nextDueAt: null) as RootDeckWorkload;

    expect(idsOf(content), ['busy', 'empty', 'rested']);
    expect(
      [for (final deck in content.decks) deck.canStudy],
      [true, false, true],
    );
  });

  test('the hero adds up the list: the due and the new cards, and the decks '
      'with work (UC-STUDY-002 step 3, BR-STUDY-068)', () {
    final content = studyHomeContentOf([
      deck('a', overdue: 3, dueToday: 2, fresh: 1),
      deck('b', dueToday: 4),
      deck('c', fresh: 5),
      deck('d'),
    ], nextDueAt: null) as RootDeckWorkload;

    expect(
      (
        content.overdueCount,
        content.dueTodayCount,
        content.newCount,
        content.dueCount,
        content.workloadDeckCount,
        content.isCaughtUp,
      ),
      (3, 6, 6, 9, 3, false),
    );
  });
}
