import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';

// What the day's notification says: the most urgent root deck by
// BR-REMINDER-006, that deck's own due count and the other roots with cards
// due (BR-REMINDER-005; reminders spec D9, D10).

ReminderDeckWorkload _root(
  String id, {
  String? name,
  int overdue = 0,
  int days = 0,
  int dueToday = 0,
}) => ReminderDeckWorkload(
  deckId: id,
  name: name ?? id,
  overdueCount: overdue,
  overdueDays: days,
  dueTodayCount: dueToday,
);

List<String> _ordered(List<ReminderDeckWorkload> roots) => [
  for (final root in [...roots]..sort(compareReminderDecks)) root.deckId,
];

void main() {
  test('nothing due is no digest, whatever the new cards '
      '(BR-REMINDER-003, UC-REMINDER-001 A3, A4)', () {
    expect(reminderDigestOf(const []), isNull);
    expect(reminderDigestOf([_root('a'), _root('b')]), isNull);
  });

  test("the digest names the most urgent root, that root's own due count and "
      'the other roots with cards due (BR-REMINDER-005, spec D9)', () {
    final digest = reminderDigestOf([
      _root('a', name: 'Alpha', overdue: 2, dueToday: 3),
      _root('b', name: 'Beta', overdue: 5),
      _root('c', name: 'Gamma', dueToday: 4),
      _root('d', name: 'Delta'),
    ])!;

    expect(digest.deckName, 'Beta');
    expect(digest.dueCount, 5);
    expect(digest.otherDeckCount, 2);
  });

  test("a root's due count is its overdue and its due-today cards together "
      '(BR-REMINDER-003)', () {
    final digest = reminderDigestOf([
      _root('a', name: 'Alpha', overdue: 2, dueToday: 3),
    ])!;

    expect(digest.dueCount, 5);
    expect(digest.otherDeckCount, 0);
  });

  test('more overdue cards come first (BR-REMINDER-006)', () {
    expect(
      _ordered([
        _root('a', overdue: 2, days: 9, dueToday: 9),
        _root('b', overdue: 3),
      ]),
      ['b', 'a'],
    );
  });

  test('with as many overdue cards, the older backlog comes first '
      '(BR-REMINDER-006, BR-STUDY-067)', () {
    expect(
      _ordered([
        _root('a', overdue: 2, days: 1, dueToday: 9),
        _root('b', overdue: 2, days: 4),
      ]),
      ['b', 'a'],
    );
  });

  test('with the same overdue cards and age, more cards due today come '
      'first (BR-REMINDER-006)', () {
    expect(
      _ordered([
        _root('a', overdue: 2, days: 1, dueToday: 2),
        _root('b', overdue: 2, days: 1, dueToday: 5),
      ]),
      ['b', 'a'],
    );
  });

  test('then the folded name, not the code units: "alpha" before "Beta" '
      '(BR-REMINDER-006, spec D10)', () {
    expect(
      _ordered([
        _root('b', name: 'Beta', dueToday: 1),
        _root('a', name: 'alpha', dueToday: 1),
      ]),
      ['a', 'b'],
    );
  });

  test('two roots equal in every count and in the folded name are ordered '
      'by id, never by the order they were read in (BR-REMINDER-006)', () {
    final first = _root('x1', name: 'Deck', dueToday: 1);
    final second = _root('x2', name: ' deck ', dueToday: 1);

    expect(_ordered([second, first]), ['x1', 'x2']);
    expect(_ordered([first, second]), ['x1', 'x2']);
    expect(reminderDigestOf([second, first])!.deckName, 'Deck');
  });
}
